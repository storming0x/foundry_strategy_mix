# Testing Yearn Strategies With Foundry

@author: https://github.com/anticlimactic

In this post, I will detail some of the challenges I faced while porting over a the [gen lev lending strategy](https://github.com/storming0x/foundry-yearnV2-gen-lev-lending) to foundry. I will try to provide some helpful pointers as well as some tips that may help speed up development. This guide assumes some familiarity with the [foundry strategy mix repository](https://github.com/storming0x/foundry_strategy_mix).

## Math In Solidity


### Floating Point Math
Math in python has some quirks which means that porting tests from pytest to solidity is not that straightforward. The main issue is that python represents both decimals and large numbers as floats whereas solidity only allows you to represent numbers as integers. When representing numbers as floats, there is [always some imprecision](https://floating-point-gui.de/formats/fp/). As a result, certain comparisons that pass in python do not pass in solidity. 

The way I have resolved this is by implementing pytest's `approx` method, which checks for a relative approximation. Mathematically, it can be stated as so:

```
b - a < b / DELTA
b: expected value
a: actual value
DELTA: maximum % difference that we are willing to accept
```

This is implemented as `assertRelApproxEq` and will be used in place of `assertEq` in places where estimations are made (e.g. `strategy.estimatedTotalAssets()`).

### Percentages

Decimals don't exist in solidity, so percentages are represented as numbers between 0 and 10000. This can make logging output a bit more difficult to read. 


## Fuzzing

### Choose Values Carefully

Choose the values you fuzz with carefully, especially when they are used in other dependencies like uniswap etc. Choosing large values may not make sense if the pools you trade in do not have enough liquidity (this can be a soft-cap on how much money the strategy can accept).

### Fuzzing Within A Range

To generate numbers within a range in foundry without getting a "too many rejects" error, you generate numbers with a smaller `uint` type (e.g. `uint16`) and then cast the number to the correct size. 

```
function testIncreaseDebtRatio(uint256 _amount, uint16 _startingDebtRatio)
    public
{
    vm_std_cheats.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
    vm_std_cheats.assume(
        _startingDebtRatio >= 100 && _startingDebtRatio < 10_000
    );
    uint256 startingDebtRatio = uint256(_startingDebtRatio);
```

In the above example, we generate numbers for _startingDebtRatio between 100 and 10 000 and then cast it to `uint256`.

If you wish to generate a number between `x + a` and `x + b` where `b < 2^32`, then you can follow a similar process to the above where you generate a number between `a` and `b` and then add it to `x`. 

### Fuzzing Enums

You can fuzz enums indirectly by fuzzing a number within a range, and then initialising the enum with that variable. Unfortunately, foundry [cannot infer enums](https://github.com/gakonst/foundry/issues/871) from the context and is unlikely to be able to do so in the future. 

```
function testApr(uint256 _amount, uint8 _swapRouter) public {
    vm_std_cheats.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
    vm_std_cheats.assume(_swapRouter <= 2);
    Strategy.SwapRouter sr = Strategy.SwapRouter(_swapRouter);
```

## General Advice

### Pin Block

When writing tests, pin the block to speed up your iteration cycles (foundry caches the fork state so it will not redownload each time). You can do this with parameter `--fork-block-number`. Note that you will have to use [alchemy's](https://www.alchemy.com/) managed node service and not infura as infura does not provide archival node data. 

### Label Addresses

Label every address that your testing contracts touch. This includes external interfaces that your contract interacts with. It will make debugging the trace a lot easier. 

### Address Spoofing

In general, I recommend using `vm_std_cheats.prank(address)` to spoof users as it makes it very clear which lines of code are being spoofed. Can also use `hoax` as a shorter replacement from `forge-std` [see hoax](https://github.com/brockelmore/forge-std/blob/8f1a9720250512a49c6638979a87613700e2a68b/src/stdlib.sol#L25)

The only times I recommend using `vm_std_cheats.startPrank(address)` is when there are function calls nested within the top-level call. 

```
vm_std_cheats.startPrank(gov);
strategy.setCollateralTargets(
    strategy.targetCollatRatio() / 2,
    strategy.maxCollatRatio(),
    strategy.maxBorrowCollatRatio(),
    strategy.daiBorrowCollatRatio()
);
vm_std_cheats.stopPrank();
```

In the above code snippet, `vm_std_cheats.prank(address)` will not work as it will run the inner functions first before running the outer ones. 

If you have any feedback please open an issue here: [Issues](https://github.com/storming0x/foundry_strategy_mix/issues) 
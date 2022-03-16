# Yearn Strategy Foundry Mix

## What you'll find here

- Basic Solidity Smart Contract for creating your own Yearn Strategy ([`Strategy.sol`](src/Strategy.sol))

- Configured github template with Foundry framework for starting your yearn strategy project.

- Sample test suite. ([`tests`](src/test/))


## How does it work for the User

Let's say Alice holds 100 DAI and wants to start earning yield % on them.

For this Alice needs to `DAI.approve(vault.address, 100)`.

Then Alice will call `Vault.deposit(100)`.

Vault will then transfer 100 DAI from Alice to itself, and mint Alice the corresponding shares.

Alice can then redeem those shares using `Vault.withdrawAll()` for the corresponding DAI balance (exchanged at `Vault.pricePerShare()`).

## Installation and Setup

1. To install with [Foundry](https://github.com/gakonst/foundry).

2. Fork this repository and create a new repository using it as template. [Create from template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

3. Clone your newly created repository recursively to include modules.

```sh
git clone --recursive https://github.com/myuser/foundry-yearn-strategy

cd foundry-yearn-strategy
```

4. Build the project.

```sh
make build
```

5. Sign up for [Infura](https://infura.io/) and generate an API key and copy your RPC url. Store it in the `ETH_RPC_URL` environment variable.
NOTE: you can use other services.

6. Use .env file
  1. Make a copy of `.env.example`
  2. Add the values for `ETH_RPC_URL` and other example vars
     NOTE: If you set up a global environment variable, that will take precedence

7. Run tests

NOTE: tests run in fork environment, you need to setup step 6 to be able to run these commands.

```sh
make test
```
Run tests with traces (very useful)

```sh
make trace
```

## Basic Use

To deploy the demo Yearn Strategy in a development environment:

TODO

## Implementing Strategy Logic

[`contracts/Strategy.sol`](contracts/Strategy.sol) is where you implement your own logic for your strategy. In particular:

- Create a descriptive name for your strategy via `Strategy.name()`.
- Invest your want tokens via `Strategy.adjustPosition()`.
- Take profits and report losses via `Strategy.prepareReturn()`.
- Unwind enough of your position to payback withdrawals via `Strategy.liquidatePosition()`.
- Unwind all of your positions via `Strategy.exitPosition()`.
- Fill in a way to estimate the total `want` tokens managed by the strategy via `Strategy.estimatedTotalAssets()`.
- Migrate all the positions managed by your strategy via `Strategy.prepareMigration()`.
- Make a list of all position tokens that should be protected against movements via `Strategy.protectedTokens()`.

## Testing

To run the tests:

```
make test
```

to run tests with traces (using console.sol):

```
make trace
```

# Resources

- Yearn [Discord channel](https://discord.com/invite/6PNv2nF/)
- [Getting help on Foundry](https://github.com/gakonst/foundry#getting-help)
- [Forge Standard Lib](https://github.com/brockelmore/forge-std)
- [Awesome Foundry](https://github.com/crisgarner/awesome-foundry)
- [Foundry Book](https://onbjerg.github.io/foundry-book/index.html)
- [Learn Foundry Tutorial](https://www.youtube.com/watch?v=Rp_V7bYiTCM)


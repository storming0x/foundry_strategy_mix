// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

import {StrategyFixture} from "./utils/Test.sol";

// NOTE: maybe is worth to make several contracts to test several operations
// and different strategy functionality
contract StrategyTest is StrategyFixture {
    using SafeERC20 for IERC20;

    IERC20 want;
    IERC20 weth;

    // NOTE: feel free change these vars to adjust for your strategy testing
    IERC20 public immutable DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public immutable WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public whale = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public user = address(1337);
    address public user2 = address(7331);
    uint256 WETH_AMT = 10 ** 18;

    // setup is run on before each test
    function setUp() public override {
        // setup vault
        super.setUp();

        // replace with your token
        want = DAI;
        weth = WETH;

        deployVaultAndStrategy(
            address(want),
            address(this),
            address(this),
            "",
            "",
            address(this),
            address(this),
            address(this)
        );

        // do here additional setup
        vault.setDepositLimit(type(uint256).max);
        tip(address(want), address(user), 10000e18);
        vm_std_cheats.deal(user, 10_000 ether);
    }

    function testSetupVaultOK() public {
        console.log("address of vault", address(vault));
        assertTrue(address(0) != address(vault));
        assertEq(vault.token(), address(want));
        assertEq(vault.depositLimit(), type(uint256).max);
    }

    // TODO: add additional check on strat params
    function testSetupStrategyOK() public {
        console.log("address of strategy", address(strategy));
        assertTrue(address(0) != address(strategy));
        assertEq(address(strategy.vault()), address(vault));
    }

    function testStrategyOperation(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        uint256 balanceBefore = want.balanceOf(address(user));
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        assertEq(want.balanceOf(address(vault)), _amount);


        // Note: need to check if this is equivalent to chain.sleep in brownie
        skip(60 * 3); // skip 3 minutes
        // harvest
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);
        // tend
        strategy.tend();

        vm_std_cheats.prank(user);
        vault.withdraw();

        assertEq(want.balanceOf(user), balanceBefore);
    }

    function testEmergencyExit(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        skip(1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // set emergency and exit
        strategy.setEmergencyExit();
        skip(1);
        strategy.harvest();
        assertLt(strategy.estimatedTotalAssets(), _amount);
    }

    function testProfitableHarvest(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        assertEq(want.balanceOf(address(vault)), _amount);

        // Harvest 1: Send funds through the strategy
        skip(1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // TODO: Add some code before harvest #2 to simulate earning yield

        // Harvest 2: Realize profit
        skip(1);
        strategy.harvest();
        skip(3600 * 6);
        uint256 profit = want.balanceOf(address(vault));
        // TODO: Uncomment the lines below
        // assertGt(want.balanceOf(address(strategy) + profit), _amount);
        // assertGt(vault.pricePerShare(), beforePps)
    }

    function testChangeDebt(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault and harvest
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        vault.updateStrategyDebtRatio(address(strategy), 5_000);
        skip(1);
        strategy.harvest();
        uint256 half = uint256(_amount / 2);
        assertEq(strategy.estimatedTotalAssets(), half);

        vault.updateStrategyDebtRatio(address(strategy), 10_000);
        skip(1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // In order to pass these tests, you will need to implement prepareReturn.
        // TODO: uncomment the following lines.
        // vault.updateStrategyDebtRatio(address(strategy), 5_000);
        // skip(1);
        // strategy.harvest();
        // assertEq(strategy.estimatedTotalAssets(), half);
    }

    function testSweep(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        vm_std_cheats.prank(user);
        (bool sent, ) = address(weth).call{value: WETH_AMT}("");
        require(sent, "failed to send ether");

        // Strategy want token doesn't work
        vm_std_cheats.prank(user);
        want.transfer(address(strategy), _amount);
        assertEq(address(want), address(strategy.want()));
        assertGt(want.balanceOf(address(strategy)), 0);

        vm_std_cheats.expectRevert("!want");
        strategy.sweep(address(want));

        // Vault share token doesn't work
        vm_std_cheats.expectRevert("!shares");
        strategy.sweep(address(vault));

        // TODO: If you add protected tokens to the strategy.
        // Protected token doesn't work
        // vm_std_cheats.expectRevert("!protected");
        // strategy.sweep(strategy.protectedToken());

        uint256 beforeBalance = weth.balanceOf(address(this));
        vm_std_cheats.prank(user);
        weth.transfer(address(strategy), WETH_AMT);
        assertNeq(address(weth), address(strategy.want()));
        assertEq(weth.balanceOf(address(user)), 0);
        strategy.sweep(address(weth));
        assertEq(weth.balanceOf(address(this)), WETH_AMT + beforeBalance);
    }

    function testTriggers(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault and harvest
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        vault.updateStrategyDebtRatio(address(strategy), 5_000);
        skip(1);
        strategy.harvest();

        strategy.harvestTrigger(0);
        strategy.tendTrigger(0);
    }
}

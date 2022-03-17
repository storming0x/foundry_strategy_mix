// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "forge-std/console.sol";

import {StrategyFixture} from "./utils/StrategyFixture.sol";

contract StrategyOperationsTest is StrategyFixture {
    // setup is run on before each test
    function setUp() public override {
        // setup vault
        super.setUp();
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

    /// Test Operations
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

        // TODO: Uncomment the lines below
        // uint256 profit = want.balanceOf(address(vault));
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
        // solhint-disable-next-line
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

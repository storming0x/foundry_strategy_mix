// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import {StrategyFixture} from "./utils/StrategyFixture.sol";

contract StrategyShutdownTest is StrategyFixture {
    function setUp() public override {
        super.setUp();
    }

    function testVaultShutdownCanWithdraw(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        assertEq(want.balanceOf(address(vault)), _amount);

        uint256 bal = want.balanceOf(user);
        if (bal > 0) {
            vm_std_cheats.prank(user);
            want.transfer(address(0), bal);
        }

        // Harvest 1: Send funds through the strategy
        skip(3600 * 7);
        vm_std_cheats.roll(block.number + 1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // Set Emergency
        vault.setEmergencyShutdown(true);

        // Withdraw (does it work, do you get what you expect)
        vm_std_cheats.prank(user);
        vault.withdraw();

        assertEq(want.balanceOf(user), _amount);
    }

    function testBasicShutdown(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        assertEq(want.balanceOf(address(vault)), _amount);

        // Harvest 1: Send funds through the strategy
        skip(1 days);
        vm_std_cheats.roll(block.number + 100);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // Earn interest
        skip(1 days);
        vm_std_cheats.roll(block.number + 1);

        // Harvest 2: Realize profit
        strategy.harvest();
        skip(6 hours);
        vm_std_cheats.roll(block.number + 1);

        // Set emergency
        vm_std_cheats.prank(strategist);
        strategy.setEmergencyExit();

        strategy.harvest(); // Remove funds from strategy

        assertEq(want.balanceOf(address(strategy)), 0);
        assertGe(want.balanceOf(address(vault)), _amount); // The vault has all funds
        // NOTE: May want to tweak this based on potential loss during migration
    }
}

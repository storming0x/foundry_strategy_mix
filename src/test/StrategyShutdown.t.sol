// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import {StrategyFixture} from "./utils/StrategyFixture.sol";

contract StrategyShutdownTest is StrategyFixture {
    function setUp() public override {
        super.setUp();
    }

    function testVaultShutdownCanWithdraw(uint256 _amount) public {
        vm_std_cheats.assume(
            _amount > 0.1 ether && _amount < 100_000_000 ether
        );
        tip(address(want), user, _amount);

        // Deposit to the vault
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

        uint256 bal = want.balanceOf(user);
        if (bal > 0) {
            vm_std_cheats.prank(user);
            want.transfer(address(0), bal);
        }

        // Harvest 1: Send funds through the strategy
        skip(3600 * 7);
        vm_std_cheats.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        // Set Emergency
        vm_std_cheats.prank(gov);
        vault.setEmergencyShutdown(true);

        // Withdraw (does it work, do you get what you expect)
        vm_std_cheats.prank(user);
        vault.withdraw();

        assertRelApproxEq(want.balanceOf(user), _amount, DELTA);
    }

    function testBasicShutdown(uint256 _amount) public {
        vm_std_cheats.assume(
            _amount > 0.1 ether && _amount < 100_000_000 ether
        );
        tip(address(want), user, _amount);

        // Deposit to the vault
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);

        // Harvest 1: Send funds through the strategy
        skip(1 days);
        vm_std_cheats.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        // Earn interest
        skip(1 days);

        // Harvest 2: Realize profit
        vm_std_cheats.prank(strategist);
        strategy.harvest();
        skip(6 hours);

        // Set emergency
        vm_std_cheats.prank(strategist);
        strategy.setEmergencyExit();

        vm_std_cheats.prank(strategist);
        strategy.harvest(); // Remove funds from strategy

        assertEq(want.balanceOf(address(strategy)), 0);
        assertGe(want.balanceOf(address(vault)), _amount); // The vault has all funds
        // NOTE: May want to tweak this based on potential loss during migration
    }
}

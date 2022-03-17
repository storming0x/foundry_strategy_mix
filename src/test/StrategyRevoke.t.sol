// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import {StrategyFixture} from "./utils/StrategyFixture.sol";

contract StrategyRevokeTest is StrategyFixture {
    function setUp() public override {
        super.setUp();
    }

    function testRevokeStrategyFromVault(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault and harvest
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        skip(1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // In order to pass these tests, you will need to implement prepareReturn.
        // TODO: uncomment the following lines.
        // vault.revokeStrategy(address(strategy));
        // skip(1);
        // strategy.harvest();
        // assertEq(want.balanceOf(address(vault)), _amount);
    }

    function testRevokeStrategyFromStrategy(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        skip(1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        strategy.setEmergencyExit();
        skip(1);
        strategy.harvest();
        assertEq(want.balanceOf(address(vault)), _amount);
    }
}

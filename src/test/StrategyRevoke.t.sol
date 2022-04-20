// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import {StrategyFixture} from "./utils/StrategyFixture.sol";

contract StrategyRevokeTest is StrategyFixture {
    function setUp() public override {
        super.setUp();
    }

    function testRevokeStrategyFromVault(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
        deal(address(want), user, _amount);

        // Deposit to the vault and harvest
        vm.prank(user);
        want.approve(address(vault), _amount);
        vm.prank(user);
        vault.deposit(_amount);
        skip(1);
        vm.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        // In order to pass these tests, you will need to implement prepareReturn.
        // TODO: uncomment the following lines.
        // vm.prank(gov);
        // vault.revokeStrategy(address(strategy));
        // skip(1);
        // vm.prank(strategist);
        // strategy.harvest();
        // assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);
    }

    function testRevokeStrategyFromStrategy(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmt && _amount < maxFuzzAmt);
        deal(address(want), user, _amount);

        vm.prank(user);
        want.approve(address(vault), _amount);
        vm.prank(user);
        vault.deposit(_amount);
        skip(1);
        vm.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(strategy.estimatedTotalAssets(), _amount, DELTA);

        vm.prank(gov);
        strategy.setEmergencyExit();
        skip(1);
        vm.prank(strategist);
        strategy.harvest();
        assertRelApproxEq(want.balanceOf(address(vault)), _amount, DELTA);
    }
}

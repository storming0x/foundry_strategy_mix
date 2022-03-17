// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import {StrategyFixture} from "./utils/StrategyFixture.sol";

// NOTE: if the name of the strat or file changes this needs to be updated
import {Strategy} from "../Strategy.sol";

contract StrategyMigrationTest is StrategyFixture {
    function setUp() public override {
        super.setUp();
    }

    // TODO: Add tests that show proper migration of the strategy to a newer one
    // Use another copy of the strategy to simmulate the migration
    // Show that nothing is lost.
    function testMigration(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        // Deposit to the vault and harvest
        vm_std_cheats.prank(user);
        want.approve(address(vault), _amount);
        vm_std_cheats.prank(user);
        vault.deposit(_amount);
        skip(1);
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);

        // Migrate to a new strategy
        vm_std_cheats.prank(strategist);
        address newStrategyAddr = deployStrategy(address(vault));
        vault.migrateStrategy(address(strategy), newStrategyAddr);
        assertEq(Strategy(newStrategyAddr).estimatedTotalAssets(), _amount);
    }
}

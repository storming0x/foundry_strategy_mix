// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {VaultFixture} from "./utils/Test.sol";
import "forge-std/console.sol";

contract StrategyTest is VaultFixture {
    function setUp() public override {
        // setup vault
        super.setUp();
    }

    function testExample() public {
        assertTrue(true);
    }

    function testVaultOK() public {
        console.log("address of vault", address(vault));
        assertTrue(address(0) != address(vault));
    }
}

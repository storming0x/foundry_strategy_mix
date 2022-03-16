// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma abicoder v2;

import {ExtendedDSTest} from "./ExtendedDSTest.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import {IVault} from "../../interface/Vault.sol";

// NOTE: if the name of the strat or file changes this needs to be updated
import {Strategy} from "../../Strategy.sol";

// Artifact paths for deploying from the deps folder, assumes that the command is run from
// the project root.
string constant vaultArtifact = 'artifacts/Vault.json';

// Base fixture deploying Vault
contract StrategyFixture is ExtendedDSTest, stdCheats {
    IVault public vault;
    Strategy public strategy;

    function setUp() public virtual {
        // setup vault
    }

    // Deploys a vault
    function deployVault(
        address _token,
        address _gov,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management
    ) public returns (address) {
        address _vault = deployCode(vaultArtifact);
        vault = IVault(_vault);

        vault.initialize(
            _token,
            _gov,
            _rewards,
            _name,
            _symbol,
            _guardian,
            _management
        );

        return address(vault);
    }

    // Deploys a strategy
    function deployStrategy(
        address _vault
    ) public returns (address) {
        Strategy _strategy = new Strategy(_vault);

        return address(_strategy);
    }

    // Deploys a vault and strategy attached to vault
    function deployVaultAndStrategy(
        address _token,
        address _gov,
        address _rewards,
        string memory _name,
        string memory _symbol,
        address _guardian,
        address _management,
        address _keeper,
        address _strategist
    ) public returns (address _vault, address _strategy) {
        _vault = deployCode(vaultArtifact);
        vault = IVault(_vault);

        vault.initialize(
            _token,
            _gov,
            _rewards,
            _name,
            _symbol,
            _guardian,
            _management
        );

        vm_std_cheats.prank(_strategist);
        _strategy = deployStrategy(_vault);
        strategy = Strategy(_strategy);

        vm_std_cheats.prank(_strategist);
        strategy.setKeeper(_keeper);

        vault.addStrategy(
            _strategy,
            10_000,
            0,
            type(uint256).max,
            1_000
        );
    }

}

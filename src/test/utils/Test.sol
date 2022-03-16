pragma solidity ^0.8.12;
pragma abicoder v2;

import "ds-test/test.sol";
import {stdCheats} from "forge-std/stdlib.sol";

// These are the core Yearn libraries
import {
    VaultAPI
} from "@yearnvaults/contracts/BaseStrategy.sol";

// Artifact paths for deploying from the deps folder, assumes that the command is run from
// the project root.
string constant vaultArtifact = 'artifacts/Vault.json';

// Base fixture deploying Vault
contract VaultFixture is DSTest, stdCheats {
    VaultAPI public vault;

    // Deploys a vault
    function setUp() public virtual {
        address _vault = deployCode(vaultArtifact);
        vault = VaultAPI(_vault);
    }
}

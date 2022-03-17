// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ExtendedDSTest} from "./ExtendedDSTest.sol";
import {stdCheats} from "forge-std/stdlib.sol";
import {IVault} from "../../interface/Vault.sol";

// NOTE: if the name of the strat or file changes this needs to be updated
import {Strategy} from "../../Strategy.sol";

// Artifact paths for deploying from the deps folder, assumes that the command is run from
// the project root.
string constant vaultArtifact = "artifacts/Vault.json";

// Base fixture deploying Vault
contract StrategyFixture is ExtendedDSTest, stdCheats {
    using SafeERC20 for IERC20;

    IVault public vault;
    Strategy public strategy;
    IERC20 public weth;
    IERC20 public want;

    // NOTE: feel free change these vars to adjust for your strategy testing
    IERC20 public constant DAI =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public whale = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public user = address(1337);
    address public strategist = address(1);
    uint256 public constant WETH_AMT = 10**18;

    function setUp() public virtual {
        weth = WETH;

        // replace with your token
        want = DAI;

        deployVaultAndStrategy(
            address(want),
            address(this),
            address(this),
            "",
            "",
            address(this),
            address(this),
            address(this),
            strategist
        );

        // do here additional setup
        vault.setDepositLimit(type(uint256).max);
        tip(address(want), address(user), 10000e18);
        vm_std_cheats.deal(user, 10_000 ether);
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
    function deployStrategy(address _vault) public returns (address) {
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

        vault.addStrategy(_strategy, 10_000, 0, type(uint256).max, 1_000);
    }
}

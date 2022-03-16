// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

import {StrategyFixture} from "./utils/Test.sol";

// NOTE: maybe is worth to make several contracts to test several operations
// and different strategy functionality
contract StrategyTest is StrategyFixture {
    using SafeERC20 for IERC20;

    IERC20 want;

    // NOTE: feel free change these vars to adjust for your strategy testing
    IERC20 public immutable DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public whale = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public user = address(1337);
    address public user2 = address(7331);

    // setup is run on before each test
    function setUp() public override {
        // setup vault
        super.setUp();

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
            address(this)
        );

        // do here additional setup
        vault.setDepositLimit(type(uint256).max);
        tip(address(want), address(this), 10000e18);
    }

    function testSetupVaultOK() public {
        console.log("address of vault", address(vault));
        assertTrue(address(0) != address(vault));
        assertEq(vault.token(), address(want));
        assertEq(vault.depositLimit(), type(uint256).max);
    }

    // TODO: add additiona check on strat params
    function testSetupStrategyOK() public {
        console.log("address of strategy", address(strategy));
        assertTrue(address(0) != address(strategy));
        assertEq(address(strategy.vault()), address(vault));
    }

    function testStrategyOperation(uint256 _amount) public {
        vm_std_cheats.assume(_amount > 0.1 ether && _amount < 10e18);

        uint balanceBefore = want.balanceOf(address(this));
        want.approve(address(vault), _amount);
        vault.deposit(_amount);
        assertEq(want.balanceOf(address(vault)), _amount);

        
        // Note: need to check if this is equivalent to chain.sleep in brownie
        skip(60 * 3); // skip 3 minutes
        // harvest
        strategy.harvest();
        assertEq(strategy.estimatedTotalAssets(), _amount);
        // tend
        strategy.tend();      

        vault.withdraw();

        assertEq(want.balanceOf(address(this)), balanceBefore);  
    }
}

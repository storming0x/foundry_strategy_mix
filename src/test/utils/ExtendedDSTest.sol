// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import "ds-test/test.sol";

contract ExtendedDSTest is DSTest {
    // solhint-disable-next-line
    function assertNeq(address a, address b) internal {
        if (a == b) {
            emit log("Error: a != b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }

    // Can be removed once https://github.com/dapphub/ds-test/pull/25 is merged and we update submodules, but useful for now
    function assertApproxEq(uint a, uint b, uint margin_of_error) internal {
        if (a > b) {
            if (a - b > margin_of_error) {
                emit log("Error a not equal to b");
                emit log_named_uint("  Expected", b);
                emit log_named_uint("    Actual", a);
                fail();
            }
        } else {
            if (b - a > margin_of_error) {
                emit log("Error a not equal to b");
                emit log_named_uint("  Expected", b);
                emit log_named_uint("    Actual", a);
                fail();
            }
        }
    }

    function assertApproxEq(uint a, uint b, uint margin_of_error, string memory err) internal {
        if (a > b) {
            if (a - b > margin_of_error) {
                emit log_named_string("Error", err);
                emit log_named_uint("  Expected", b);
                emit log_named_uint("    Actual", a);
                fail();
            }
        } else {
            if (b - a > margin_of_error) {
                emit log_named_string("Error", err);
                emit log_named_uint("  Expected", b);
                emit log_named_uint("    Actual", a);
                fail();
            }
        }
    }
}

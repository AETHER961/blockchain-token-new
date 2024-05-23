// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Token_TokensReleased} from "tests/sol/scenarios/TokenScenarios.t.sol";

contract Gas_Token_transfer is Token_TokensReleased {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(address(USER_1));
    }

    function test_gas_transfer() public {
        _token.transfer(USER_2, MINT_AMOUNT);
    }
}

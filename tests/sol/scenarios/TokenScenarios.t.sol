// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BaseTest} from "tests/sol/BaseTest.t.sol";
import {TX_FEE_DENOMINATOR} from "agau-common/admin-ops/WhitelistTypes.sol";

abstract contract Token_InitSetup is BaseTest {
    function testSkip() public virtual override {}

    function _calculateTxFee(uint256 amount) internal pure returns (uint256 fee) {
        fee = (amount * TX_FEE_RATE) / TX_FEE_DENOMINATOR;
    }
}

abstract contract Token_TokensMintedAndLocked is Token_InitSetup {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(address(_tokenManager));
        _token.mintAndLock(USER_1, MINT_AMOUNT);
    }

    function testSkip() public virtual override {}
}

abstract contract Token_TokensReleased is Token_TokensMintedAndLocked {
    function setUp() public virtual override {
        Token_TokensMintedAndLocked.setUp();

        vm.prank(address(_tokenManager));
        _token.release(USER_1, MINT_AMOUNT);
    }

    function testSkip() public virtual override {}
}

abstract contract Token_TokensFrozen is Token_TokensReleased {
    function setUp() public override {
        super.setUp();

        vm.prank(address(_tokenManager));
        _token.lock(USER_1, MINT_AMOUNT);
    }

    function testSkip() public virtual override {}
}

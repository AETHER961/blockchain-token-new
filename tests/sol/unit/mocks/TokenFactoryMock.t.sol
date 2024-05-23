// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {TokenFactory} from "contracts/token/TokenFactory.sol";

abstract contract TokenFactoryMock is Test {
    address public tokenFactory = makeAddr("tokenFactory");

    function mockCall_tokenFactory_tokenForId(uint256 tokenId, address token_) internal {
        vm.mockCall(
            tokenFactory,
            abi.encodeCall(TokenFactory.tokenForId, (tokenId)),
            abi.encode(token_)
        );
    }

    function testSkip() public virtual {}
}

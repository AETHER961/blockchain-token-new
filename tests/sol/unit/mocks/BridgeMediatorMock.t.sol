// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {BridgeMediator} from "agau-common-bridge/BridgeMediator.sol";

abstract contract BridgeMediatorMock is Test {
    address public bridgeMediator = makeAddr("bridgeMediator");

    function expectCall_bridgeMediator_sendMessage(bytes memory data, bytes32 messageId) internal {
        vm.mockCall(
            bridgeMediator,
            abi.encodeCall(BridgeMediator.sendMessage, (data)),
            abi.encode(messageId)
        );
        vm.expectCall(bridgeMediator, abi.encodeCall(BridgeMediator.sendMessage, (data)));
    }

    function mockCall_bridgeMediator_messageExecuted(bytes32 messageId, bool executed) internal {
        vm.mockCall(
            bridgeMediator,
            abi.encodeCall(BridgeMediator.messageCallStatus, (messageId)),
            abi.encode(executed)
        );
    }

    function mockCall_bridgeMediator_messageReverted(bytes32 messageId, bool reverted) internal {
        vm.mockCall(
            bridgeMediator,
            abi.encodeCall(BridgeMediator.messageReverted, messageId),
            abi.encode(reverted)
        );
    }

    function testSkip() public virtual {}
}

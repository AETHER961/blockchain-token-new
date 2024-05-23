// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {Constants} from "tests/sol/Constants.t.sol";

import {BridgeMediator} from "agau-common-bridge/BridgeMediator.sol";

abstract contract BridgeMediatorMock is Test, Constants {
    address internal _bridgeMediator = makeAddr("bridgeMediator");

    function mockCall_bridgeMediator_messageCallStatus(bytes32 messageId, bool executed) internal {
        bytes memory data = abi.encodeWithSelector(
            BridgeMediator.messageCallStatus.selector,
            messageId
        );
        vm.mockCall(_bridgeMediator, data, abi.encode(executed));
    }

    function mockCall_bridgeMediator_messageReverted(bool reverted) internal {
        vm.mockCall(
            address(_bridgeMediator),
            abi.encodeCall(BridgeMediator.messageReverted, RECEIVED_MESSAGE_ID),
            abi.encode(reverted)
        );
    }

    function mockCall_bridgeMediator_messageSend(bytes memory data) internal {
        vm.mockCall(
            address(_bridgeMediator),
            abi.encodeCall(BridgeMediator.sendMessage, data),
            abi.encode(SEND_MESSAGE_ID)
        );
    }

    // add this to exclude contract from coverage report
    function testSkip() public virtual {}
}

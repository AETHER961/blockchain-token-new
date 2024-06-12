// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {TokenManager} from "contracts/management/TokenManager.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BridgeInteractor} from "agau-common-bridge/BridgeInteractor.sol";
import {BridgeMediator} from "agau-common-bridge/BridgeMediator.sol";

import {
    TokenManager_InitSetup,
    TokenManager_TokensMintedAndLocked_SingleMessage,
    TokenManager_TokensReceivedForRedemption_SingleMessage,
    TokenManager_TokensReceivedForRedemption_MultipleMessages,
    TokenManager_TokensReleased_SingleMessage,
    TokenManager_TokensFrozen,
    TokenManager_FeeDiscountGroupCreated
} from "tests/sol/scenarios/TokenManagerScenarios.t.sol";

import {OpType} from "agau-common/admin-ops/OpsTypes.sol";
import {
    CommonTokenOp,
    TokenManagementOp,
    BurnTokenOp,
    TokenTransferOp,
    CreateFeeDiscountGroupOp,
    UpdateFeeDiscountGroupOp,
    UserDiscountGroupOp,
    TransactionFeeRateOp,
    FeeAmountRangeOp
} from "agau-common-bridge/TokenOpTypes.sol";
import {
    DISCOUNT_RATE_DENOMINATOR,
    TX_FEE_DENOMINATOR,
    DiscountType,
    Discount
} from "agau-common/admin-ops/WhitelistTypes.sol";

import {IOpsRecovery} from "agau-common/admin-ops/interface/IOpsRecovery.sol";
import {
    ITokenizationRecovery
} from "agau-common/tokens-management/tokenization/interface/ITokenizationRecovery.sol";
import {
    IRedemptionRecovery
} from "agau-common/tokens-management/redemption/interface/IRedemptionRecovery.sol";
import {
    IRedemptionCallback
} from "agau-common/tokens-management/redemption/interface/IRedemptionCallback.sol";

contract TokenManager_MintAndLockTokens is TokenManager_InitSetup {
    CommonTokenOp[] internal _msgs;

    function test_revertsWhen_callerNotBridge() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.mintAndLockTokens(_msgs);
    }

    function test_tokensProperlyMintedAndLocked() public {
        _msgs = _generateCommonTokenOpMessages(1, WEIGHT);

        for (uint256 i; i < _msgs.length; i++) {
            assertEq(_token.balanceOf(_msgs[i].account), 0);
            assertEq(_token.lockedBalanceOf(_msgs[i].account), 0);
        }

        vm.prank(address(_bridgeMediator));
        _tokenManager.mintAndLockTokens(_msgs);

        for (uint256 i; i < _msgs.length; i++) {
            assertEq(_token.balanceOf(_msgs[i].account), 0);
            assertEq(
                _token.lockedBalanceOf(_msgs[i].account),
                _tokenManager.toTokenAmount(_token, _msgs[i].weight)
            );
        }
    }
}

contract TokenManager_ReleaseTokens is TokenManager_TokensMintedAndLocked_SingleMessage {
    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.releaseTokens(_commonMsgs);
    }

    function test_tokensProperlyReleased() public {
        for (uint256 i; i < _commonMsgs.length; i++) {
            assertEq(_token.balanceOf(_commonMsgs[i].account), 0);
            assertEq(
                _token.lockedBalanceOf(_commonMsgs[i].account),
                _tokenManager.toTokenAmount(_token, _commonMsgs[i].weight)
            );
        }

        vm.prank(address(_bridgeMediator));
        _tokenManager.releaseTokens(_commonMsgs);

        for (uint256 i; i < _commonMsgs.length; i++) {
            assertEq(
                _token.balanceOf(_commonMsgs[i].account),
                _tokenManager.toTokenAmount(_token, _commonMsgs[i].weight)
            );
            assertEq(_token.lockedBalanceOf(_commonMsgs[i].account), 0);
        }
    }
}

contract TokenManager_BurnTokens is TokenManager_TokensReceivedForRedemption_MultipleMessages {
    BurnTokenOp[] internal _msgs;

    function test_revertsWhen_callerNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(USER_1);
        _tokenManager.burnTokens(_msgs);
    }

    function test_tokensProperlyBurned() public {
        _msgs = _generateBurnTokenOpMessages(_commonMsgs);

        uint256 expectedRedeemAmount;
        for (uint256 i; i < _msgs.length; i++) {
            expectedRedeemAmount += _tokenManager.toTokenAmount(_token, _msgs[i].weight);
        }

        assertEq(_token.balanceOf(address(_tokenManager)), expectedRedeemAmount);

        vm.prank(address(_bridgeMediator));
        _tokenManager.burnTokens(_msgs);

        assertEq(_token.balanceOf(address(_tokenManager)), 0);
    }
}

contract TokenManager_ExecuteBurnTokensCallback is TokenManager_InitSetup {
    function test_revertsWhen_messageNotExecuted(bytes32 messageId) public {
        mockCall_bridgeMediator_messageCallStatus(messageId, false);

        vm.expectRevert(
            abi.encodeWithSelector(TokenManager.MessageNotExecuted.selector, messageId)
        );

        _tokenManager.executeBurnTokensCallback(messageId);
    }

    function test_callbackMessageSend(bytes32 messageId) public {
        mockCall_bridgeMediator_messageCallStatus(messageId, true);

        _tokenManager.executeBurnTokensCallback(messageId);
    }
}

contract TokenManager_RefundTokens is TokenManager_TokensReceivedForRedemption_MultipleMessages {
    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.refundTokens(_commonMsgs);
    }

    function test_tokensProperlyRefunded() public {
        uint256 expectedRedeemAmount;
        for (uint256 i; i < _commonMsgs.length; i++) {
            expectedRedeemAmount += _tokenManager.toTokenAmount(_token, _commonMsgs[i].weight);
            assertEq(_token.balanceOf(_commonMsgs[i].account), 0);
        }

        assertEq(_token.balanceOf(address(_tokenManager)), expectedRedeemAmount);

        vm.prank(address(_bridgeMediator));
        _tokenManager.refundTokens(_commonMsgs);

        for (uint256 i; i < _commonMsgs.length; i++) {
            assertEq(
                _token.balanceOf(_commonMsgs[i].account),
                _tokenManager.toTokenAmount(_token, _commonMsgs[i].weight)
            );
        }
        assertEq(_token.balanceOf(address(_tokenManager)), 0);
    }
}

contract TokenManager_FreezeTokens is TokenManager_TokensReleased_SingleMessage {
    TokenManagementOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.freezeTokens(_msg);
    }

    function test_tokensProperlyFrozen() public {
        _msg = _generateTokenManagementOpMessage(_commonMsgs[0]);
        address account = _msg.user;
        uint256 amount = _msg.amount;

        assertEq(_token.balanceOf(account), amount);
        assertEq(_token.lockedBalanceOf(account), 0);

        vm.prank(address(_bridgeMediator));
        _tokenManager.freezeTokens(_msg);

        assertEq(_token.balanceOf(account), 0);
        assertEq(_token.lockedBalanceOf(account), amount);
    }
}

contract TokenManager_UnfreezeTokens is TokenManager_TokensFrozen {
    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.unfreezeTokens(_tokenManagementMsg);
    }

    function test_tokensProperlyUnfrozen() public {
        address account = _tokenManagementMsg.user;
        uint256 amount = _tokenManagementMsg.amount;

        assertEq(_token.balanceOf(account), 0);
        assertEq(_token.lockedBalanceOf(account), amount);

        vm.prank(address(_bridgeMediator));
        _tokenManager.unfreezeTokens(_tokenManagementMsg);

        assertEq(_token.balanceOf(account), amount);
        assertEq(_token.lockedBalanceOf(account), 0);
    }
}

contract TokenManager_SeizeTokens is TokenManager_TokensFrozen {
    TokenTransferOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.seizeTokens(_msg);
    }

    function test_tokensProperlySeized() public {
        _msg = _generateTokenTransferOpMessage(_tokenManagementMsg);

        address from = _msg.from;
        address to = _msg.to;
        uint256 amount = _tokenManagementMsg.amount;

        assertEq(_token.balanceOf(from), 0);
        assertEq(_token.balanceOf(to), 0);
        assertEq(_token.lockedBalanceOf(from), amount);

        vm.prank(address(_bridgeMediator));
        _tokenManager.seizeTokens(_msg);

        assertEq(_token.balanceOf(from), 0);
        assertEq(_token.lockedBalanceOf(from), 0);
        assertEq(_token.balanceOf(to), amount);
    }
}

contract TokenManager_TransferTokens is TokenManager_TokensReceivedForRedemption_SingleMessage {
    TokenTransferOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(USER_1);
        _tokenManager.transferTokens(_msg);
    }

    function test_transfersProperAmount() public {
        _msg = _generateTokenTransferOpMessage(_commonMsgs[0]);
        address from = address(_tokenManager);
        address to = _msg.to;
        uint256 amount = _msg.amount;

        assertEq(_token.balanceOf(to), 0);
        assertEq(_token.balanceOf(from), amount);

        vm.prank(address(_bridgeMediator));
        _tokenManager.transferTokens(_msg);

        assertEq(_token.balanceOf(from), 0);
        assertEq(_token.balanceOf(to), amount);
    }
}

contract TokenManager_CreateDiscountGroup is TokenManager_InitSetup {
    CreateFeeDiscountGroupOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(USER_1);
        _tokenManager.createDiscountGroup(_msg);
    }

    function test_createsDiscountGroup() public {
        _msg = _generateCreateDiscountGroupMessage();
        uint256 discountGroupCount = _feesManager.discountGroupCount(TX_GROUP_TYPE);

        vm.prank(address(_bridgeMediator));
        _tokenManager.createDiscountGroup(_msg);

        uint256 discountGroupId = _feesManager.discountGroupCount(TX_GROUP_TYPE);
        Discount memory discount = _feesManager.discount(TX_GROUP_TYPE, discountGroupId);
        assertEq(discountGroupId, discountGroupCount + 1);
        assertEq(discount.value, DISCOUNT_VALUE);
        assertEq(uint8(discount.discountType), uint8(DISCOUNT_TYPE));
    }
}

contract TokenManager_UpdateDiscountGroup is TokenManager_FeeDiscountGroupCreated {
    UpdateFeeDiscountGroupOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.updateDiscountGroup(_msg);
    }

    function test_updatesDiscountGroup(uint248 updatedValue, uint8 updatedDiscountType) public {
        vm.assume(updatedValue != DISCOUNT_VALUE);
        vm.assume(updatedValue < DISCOUNT_RATE_DENOMINATOR);

        updatedDiscountType = uint8(bound(updatedDiscountType, 1, uint8(type(DiscountType).max)));
        vm.assume(updatedDiscountType != 0 && updatedDiscountType != uint8(DISCOUNT_TYPE));

        _msg = _generateUpdateDiscountGroupMessage(updatedValue, DiscountType(updatedDiscountType));
        uint256 discountGroupCount = _feesManager.discountGroupCount(TX_GROUP_TYPE);

        vm.prank(address(_bridgeMediator));
        _tokenManager.updateDiscountGroup(_msg);

        uint256 discountGroupId = _feesManager.discountGroupCount(TX_GROUP_TYPE);
        Discount memory discount = _feesManager.discount(TX_GROUP_TYPE, discountGroupId);
        assertEq(discountGroupId, discountGroupCount);
        assertEq(discount.value, updatedValue);
        assertEq(uint8(discount.discountType), updatedDiscountType);
    }
}

contract TokenManager_SetUserDiscountGroup is TokenManager_FeeDiscountGroupCreated {
    UserDiscountGroupOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.setUserDiscountGroup(_msg);
    }

    function test_setsUserForDiscountGroup() public {
        _msg = _generateUserDiscountGroupMessage();
        uint256 prevDiscountGroupForUser = _feesManager.discountGroupIdForUser(
            TX_GROUP_TYPE,
            USER_1
        );
        assertEq(prevDiscountGroupForUser, 0);

        vm.prank(address(_bridgeMediator));
        _tokenManager.setUserDiscountGroup(_msg);

        uint256 newDiscountGroupForUser = _feesManager.discountGroupIdForUser(
            TX_GROUP_TYPE,
            USER_1
        );
        assertNotEq(newDiscountGroupForUser, prevDiscountGroupForUser);
    }
}

contract TokenManager_UpdateTransactionFeeRate is TokenManager_InitSetup {
    TransactionFeeRateOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.updateTransactionFeeRate(_msg);
    }

    function test_updatesTransactionFeeRate(uint256 newFeeRate) public {
        vm.assume(newFeeRate != TX_FEE_RATE);
        vm.assume(newFeeRate <= TX_FEE_DENOMINATOR);

        _msg = _generateTransactionFeeRateMessage(newFeeRate);
        uint256 prevFeeRate = _feesManager.txFeeRate();
        assertEq(prevFeeRate, TX_FEE_RATE);

        vm.prank(address(_bridgeMediator));
        _tokenManager.updateTransactionFeeRate(_msg);

        assertEq(_feesManager.txFeeRate(), newFeeRate);
    }
}

contract TokenManager_UpdateFeeAmountRange is TokenManager_InitSetup {
    FeeAmountRangeOp internal _msg;

    function test_revertsWhen_callerNotBridgeMediator() public {
        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));
        vm.prank(USER_1);
        _tokenManager.updateFeeAmountRange(_msg);
    }

    function test_updatesFeeAmountRange(uint256 newMinFeeAmount, uint256 newMaxFeeAmount) public {
        vm.assume(newMinFeeAmount <= newMaxFeeAmount);

        _msg = _generateFeeAmountRangeMessage(newMinFeeAmount, newMaxFeeAmount);

        assertEq(_feesManager.minTxFee(), MIN_TX_FEE);
        assertEq(_feesManager.maxTxFee(), MAX_TX_FEE);

        vm.prank(address(_bridgeMediator));
        _tokenManager.updateFeeAmountRange(_msg);

        assertEq(_feesManager.minTxFee(), newMinFeeAmount);
        assertEq(_feesManager.maxTxFee(), newMaxFeeAmount);
    }
}

contract TokenManager_FixReleaseTokensMessage is TokenManager_InitSetup {
    function test_revertsWhen_messageNotFixable() public {
        mockCall_bridgeMediator_messageReverted(false);
        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, RECEIVED_MESSAGE_ID)
        );

        vm.prank(USER_1);
        _tokenManager.fixReleaseTokensMessage(RECEIVED_MESSAGE_ID);
    }

    function test_fixMessageSend() public {
        mockCall_bridgeMediator_messageReverted(true);
        mockCall_bridgeMediator_messageSend(
            abi.encodeCall(ITokenizationRecovery.fixReleaseTokensMessage, RECEIVED_MESSAGE_ID)
        );

        vm.expectEmit(address(_tokenManager));
        emit FixReleaseTokensMessageSend(RECEIVED_MESSAGE_ID, SEND_MESSAGE_ID);
        vm.prank(USER_1);
        _tokenManager.fixReleaseTokensMessage(RECEIVED_MESSAGE_ID);
    }
}

contract TokenManager_FixBurnTokensMessage is TokenManager_InitSetup {
    function test_revertsWhen_messageNotFixable() public {
        mockCall_bridgeMediator_messageReverted(false);
        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, RECEIVED_MESSAGE_ID)
        );

        vm.prank(USER_1);
        _tokenManager.fixBurnTokensMessage(RECEIVED_MESSAGE_ID);
    }

    function test_fixMessageSend() public {
        mockCall_bridgeMediator_messageReverted(true);
        mockCall_bridgeMediator_messageSend(
            abi.encodeCall(IRedemptionRecovery.fixBurnTokensMessage, RECEIVED_MESSAGE_ID)
        );

        vm.expectEmit(address(_tokenManager));
        emit FixBurnTokensMessageSend(RECEIVED_MESSAGE_ID, SEND_MESSAGE_ID);
        vm.prank(USER_1);
        _tokenManager.fixBurnTokensMessage(RECEIVED_MESSAGE_ID);
    }
}

contract TokenManager_fixRefundTokensMessage is TokenManager_InitSetup {
    function test_revertsWhen_messageNotFixable() public {
        mockCall_bridgeMediator_messageReverted(false);
        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, RECEIVED_MESSAGE_ID)
        );

        vm.prank(USER_1);
        _tokenManager.fixRefundTokensMessage(RECEIVED_MESSAGE_ID);
    }

    function test_fixMessageSend() public {
        mockCall_bridgeMediator_messageReverted(true);
        mockCall_bridgeMediator_messageSend(
            abi.encodeCall(IRedemptionRecovery.fixRefundTokensMessage, RECEIVED_MESSAGE_ID)
        );

        vm.expectEmit(address(_tokenManager));
        emit FixRefundTokensMessageSend(RECEIVED_MESSAGE_ID, SEND_MESSAGE_ID);
        vm.prank(USER_1);
        _tokenManager.fixRefundTokensMessage(RECEIVED_MESSAGE_ID);
    }
}

contract TokenManager_FixOpsMessage is TokenManager_InitSetup {
    function test_revertsWhen_messageNotFixable(uint8 opType) public {
        mockCall_bridgeMediator_messageReverted(false);
        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, RECEIVED_MESSAGE_ID)
        );

        vm.prank(USER_1);
        _tokenManager.fixOpsMessage(_opTypeEnum(opType), RECEIVED_MESSAGE_ID);
    }

    function test_fixMessageSend(uint8 opType) public {
        OpType opType_ = _opTypeEnum(opType);

        mockCall_bridgeMediator_messageReverted(true);
        mockCall_bridgeMediator_messageSend(
            abi.encodeCall(IOpsRecovery.fixMessage, RECEIVED_MESSAGE_ID)
        );

        vm.expectEmit(address(_tokenManager));
        emit OpFixMessageSend(opType_, RECEIVED_MESSAGE_ID, SEND_MESSAGE_ID);
        vm.prank(USER_1);
        _tokenManager.fixOpsMessage(opType_, RECEIVED_MESSAGE_ID);
    }

    function _opTypeEnum(uint8 opType) private pure returns (OpType) {
        return OpType(uint8(bound(opType, uint8(type(OpType).min), uint8(type(OpType).max))));
    }
}

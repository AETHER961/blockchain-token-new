// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {TokenManager} from "contracts/management/TokenManager.sol";

import {MetalToken} from "contracts/token/MetalToken.sol";
import {BridgeInteractor} from "agau-common/bridge/BridgeInteractor.sol";

import {OpType} from "agau-common/admin-ops/OpsTypes.sol";
import {
    CommonTokenOpMessage,
    BurnTokenOpMessage,
    TokenManagementOpMessage,
    TokenTransferOpMessage,
    CreateFeeDiscountGroupOpMessage,
    UpdateFeeDiscountGroupOpMessage,
    UserDiscountGroupOpMessage,
    FeeAmountRangeOpMessage,
    TransactionFeeRateOpMessage
} from "agau-common-bridge/TokenOpTypes.sol";
import {WhitelistGroupType, Discount, DiscountType} from "agau-common/admin-ops/WhitelistTypes.sol";

import {BridgeMediatorMock} from "tests/sol/unit/mocks/BridgeMediatorMock.t.sol";
import {MetalTokenMock} from "tests/sol/unit/mocks/MetalTokenMock.t.sol";
import {FeesManagerMock} from "tests/sol/unit/mocks/FeesManagerMock.t.sol";
import {TokenFactoryMock} from "tests/sol/unit/mocks/TokenFactoryMock.t.sol";

import {
    ITokenizationRecovery
} from "agau-common-management/tokenization/interface/ITokenizationRecovery.sol";
import {
    IRedemptionCallback
} from "agau-common-management/redemption/interface/IRedemptionCallback.sol";
import {
    IRedemptionRecovery
} from "agau-common-management/redemption/interface/IRedemptionRecovery.sol";
import {IOpsRecovery} from "agau-common/admin-ops/interface/IOpsRecovery.sol";

contract TokenManagerTest is
    Test,
    BridgeMediatorMock,
    MetalTokenMock,
    FeesManagerMock,
    TokenFactoryMock
{
    TokenManager public tokenManager;

    // Copied from TokenManager.sol
    event TokenBurnCallbackSend(bytes32 indexed messageId);
    event FixReleaseTokensMessageSend(
        bytes32 indexed fixingMessageId,
        bytes32 indexed fixMessageId
    );
    event FixBurnTokensMessageSend(bytes32 indexed fixingMessageId, bytes32 indexed fixMessageId);
    event FixRefundTokensMessageSend(bytes32 indexed fixingMessageId, bytes32 indexed fixMessageId);
    event OpFixMessageSend(
        OpType indexed opType,
        bytes32 indexed fixingMessageId,
        bytes32 indexed fixMessageId
    );

    function setUp() public {
        tokenManager = new TokenManager(bridgeMediator, tokenFactory, feesManager);
    }

    function testSkip()
        public
        virtual
        override(BridgeMediatorMock, FeesManagerMock, MetalTokenMock, TokenFactoryMock)
    {}

    //-------------------
    // `constructor` tests
    //-------------------

    function test_constructor_properSetup() public {
        tokenManager = new TokenManager(bridgeMediator, tokenFactory, feesManager);
        assertEq(tokenManager.bridgeMediator(), bridgeMediator);
        assertEq(tokenManager.tokenFactory(), tokenFactory);
        assertEq(tokenManager.feesManager(), feesManager);
    }

    //-------------------
    // `mintAndLockTokens` tests
    //-------------------

    function test_mintAndLockTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.mintAndLockTokens(new CommonTokenOpMessage[](0));
    }

    function test_mintAndLockTokens_properlyExecuted(uint8 metalId, uint48 weight) public {
        CommonTokenOpMessage[] memory msgs = new CommonTokenOpMessage[](1);
        msgs[0] = CommonTokenOpMessage({
            account: makeAddr("account"),
            weight: weight,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_mintAndLock(msgs[0].account, weight);

        vm.prank(bridgeMediator);
        tokenManager.mintAndLockTokens(msgs);
    }

    //-------------------
    // `releaseTokens` tests
    //-------------------

    function test_releaseTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.releaseTokens(new CommonTokenOpMessage[](0));
    }

    function test_releaseTokens_properlyExecuted(uint8 metalId, uint48 weight) public {
        CommonTokenOpMessage[] memory msgs = new CommonTokenOpMessage[](1);
        msgs[0] = CommonTokenOpMessage({
            account: makeAddr("account"),
            weight: weight,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_release(msgs[0].account, weight);

        vm.prank(bridgeMediator);
        tokenManager.releaseTokens(msgs);
    }

    //-------------------
    // `burnTokens` tests
    //-------------------

    function test_burnTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.burnTokens(new BurnTokenOpMessage[](0));
    }

    function test_burnTokens_properlyExecuted(uint8 metalId, uint48 weight) public {
        BurnTokenOpMessage[] memory msgs = new BurnTokenOpMessage[](1);
        msgs[0] = BurnTokenOpMessage({weight: weight, metalId: metalId});

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_burnTokens(address(tokenManager), weight);

        vm.prank(bridgeMediator);
        tokenManager.burnTokens(msgs);
    }

    //-------------------
    // `executeBurnTokensCallback` tests
    //-------------------

    function test_executeBurnTokensCallback_revertsWhen_messageNotExecuted(
        bytes32 messageId
    ) public {
        mockCall_bridgeMediator_messageExecuted(messageId, false);

        vm.expectRevert(
            abi.encodeWithSelector(TokenManager.MessageNotExecuted.selector, messageId)
        );

        tokenManager.executeBurnTokensCallback(messageId);
    }

    function test_executeBurnTokensCallback_executesProperly(bytes32 messageId) public {
        mockCall_bridgeMediator_messageExecuted(messageId, true);
        expectCall_bridgeMediator_sendMessage(
            abi.encodeCall(IRedemptionCallback.onTokensBurned, (messageId)),
            bytes32(uint256(0))
        );

        vm.expectEmit(address(tokenManager));
        emit TokenBurnCallbackSend(messageId);

        tokenManager.executeBurnTokensCallback(messageId);
    }

    //-------------------
    // `refundTokens` tests
    //-------------------

    function test_refundTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.refundTokens(new CommonTokenOpMessage[](0));
    }

    function test_refundTokens_properlyExecuted(uint8 metalId, uint48 weight) public {
        CommonTokenOpMessage[] memory msgs = new CommonTokenOpMessage[](1);
        msgs[0] = CommonTokenOpMessage({
            account: makeAddr("account"),
            weight: weight,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_transfer(msgs[0].account, weight);

        vm.prank(bridgeMediator);
        tokenManager.refundTokens(msgs);
    }

    //-------------------
    // `freezeTokens` tests
    //-------------------

    function test_freezeTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.freezeTokens(
            TokenManagementOpMessage({user: address(0), amount: 0, metalId: 0})
        );
    }

    function test_freezeTokens_properlyExecuted(uint256 amount, uint8 metalId) public {
        TokenManagementOpMessage memory msg_ = TokenManagementOpMessage({
            user: makeAddr("user"),
            amount: amount,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_lock(msg_.user, amount);

        vm.prank(bridgeMediator);
        tokenManager.freezeTokens(msg_);
    }

    //-------------------
    // `unfreezeTokens` tests
    //-------------------

    function test_unfreezeTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.unfreezeTokens(
            TokenManagementOpMessage({user: address(0), amount: 0, metalId: 0})
        );
    }

    function test_unfreezeTokens_properlyExecuted(uint256 amount, uint8 metalId) public {
        TokenManagementOpMessage memory msg_ = TokenManagementOpMessage({
            user: makeAddr("user"),
            amount: amount,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_unlock(msg_.user, amount);

        vm.prank(bridgeMediator);
        tokenManager.unfreezeTokens(msg_);
    }

    //-------------------
    // `seizeTokens` tests
    //-------------------

    function test_seizeTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.seizeTokens(
            TokenTransferOpMessage({from: address(0), to: address(0), amount: 0, metalId: 0})
        );
    }

    function test_seizeTokens_properlyExecuted(uint8 metalId, uint256 amount) public {
        TokenTransferOpMessage memory msg_ = TokenTransferOpMessage({
            from: makeAddr("from"),
            to: makeAddr("to"),
            amount: amount,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_seizeLocked(msg_.from, msg_.to, amount);

        vm.prank(bridgeMediator);
        tokenManager.seizeTokens(msg_);
    }

    //-------------------
    // `transferTokens` tests
    //-------------------

    function test_transferTokens_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.transferTokens(
            TokenTransferOpMessage({from: address(0), to: address(0), amount: 0, metalId: 0})
        );
    }

    function test_transferTokens_properlyExecuted(uint256 amount, uint8 metalId) public {
        TokenTransferOpMessage memory msg_ = TokenTransferOpMessage({
            from: makeAddr("from"),
            to: makeAddr("to"),
            amount: amount,
            metalId: metalId
        });

        mockCall_tokenFactory_tokenForId(metalId, token);
        mockCall_token_decimals(0);
        expectCall_token_transfer(msg_.to, amount);

        vm.prank(bridgeMediator);
        tokenManager.transferTokens(msg_);
    }

    //-------------------
    // `createDiscountGroup` tests
    //-------------------

    function test_createDiscountGroup_revertsWhen_callerNotMediator(address nonMediator) public {
        vm.assume(nonMediator != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(nonMediator);
        tokenManager.createDiscountGroup(
            CreateFeeDiscountGroupOpMessage({
                groupType: WhitelistGroupType.None,
                discount: Discount({value: 0, discountType: DiscountType.None})
            })
        );
    }

    function test_createDiscountGroup_properlyExecuted() public {
        CreateFeeDiscountGroupOpMessage memory msg_ = CreateFeeDiscountGroupOpMessage({
            groupType: WhitelistGroupType.None,
            discount: Discount({value: 0, discountType: DiscountType.None})
        });

        expectCall_feesManager_createDiscountGroup(msg_.groupType, msg_.discount);

        vm.prank(bridgeMediator);
        tokenManager.createDiscountGroup(msg_);
    }

    //-------------------
    // `updateDiscountGroup` tests
    //-------------------

    function test_updateDiscountGroup_revertsWhen_callerNotMediator(address account) public {
        vm.assume(account != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(account);
        tokenManager.updateDiscountGroup(
            UpdateFeeDiscountGroupOpMessage({
                groupType: WhitelistGroupType.None,
                discount: Discount({value: 0, discountType: DiscountType.None}),
                groupId: 0
            })
        );
    }

    function test_updateDiscountGroup_properlyExecuted() public {
        UpdateFeeDiscountGroupOpMessage memory msg_ = UpdateFeeDiscountGroupOpMessage({
            groupType: WhitelistGroupType.None,
            discount: Discount({value: 0, discountType: DiscountType.None}),
            groupId: 0
        });

        expectCall_feesManager_updateDiscountGroup(msg_.groupType, msg_.discount, msg_.groupId);

        vm.prank(bridgeMediator);
        tokenManager.updateDiscountGroup(msg_);
    }

    //-------------------
    // `setUserDiscountGroup` tests
    //-------------------

    function test_setUserDiscountGroup_revertsWhen_callerNotMediator(address account) public {
        vm.assume(account != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(account);
        tokenManager.setUserDiscountGroup(
            UserDiscountGroupOpMessage({
                groupType: WhitelistGroupType.None,
                user: address(0),
                groupId: 0
            })
        );
    }

    function test_setUserDiscountGroup_properlyExecuted() public {
        UserDiscountGroupOpMessage memory msg_ = UserDiscountGroupOpMessage({
            groupType: WhitelistGroupType.None,
            user: makeAddr("user"),
            groupId: 0
        });

        expectCall_feesManager_setGroupForUser(msg_.groupType, msg_.groupId, msg_.user);

        vm.prank(bridgeMediator);
        tokenManager.setUserDiscountGroup(msg_);
    }

    //-------------------
    // `updateTransactionFeeRate` tests
    //-------------------

    function test_updateTransactionFeeRate_revertsWhen_callerNotMediator(address account) public {
        vm.assume(account != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(account);
        tokenManager.updateTransactionFeeRate(TransactionFeeRateOpMessage({feeRate: 0}));
    }

    function test_updateTransactionFeeRate_properlyExecuted(uint256 txFeeRate) public {
        expectCall_feesManager_setTxFeeRate(txFeeRate);

        vm.prank(bridgeMediator);
        tokenManager.updateTransactionFeeRate(TransactionFeeRateOpMessage({feeRate: txFeeRate}));
    }

    //-------------------
    // `updateFeeAmountRange` tests
    //-------------------

    function test_updateFeeAmountRange_revertsWhen_callerNotMediator(address account) public {
        vm.assume(account != bridgeMediator);

        vm.expectRevert(abi.encodeWithSelector(BridgeInteractor.CallerNotMediator.selector));

        vm.prank(account);
        tokenManager.updateFeeAmountRange(
            FeeAmountRangeOpMessage({minimumAmount: 0, maximumAmount: 0})
        );
    }

    function test_updateFeeAmountRange_properlyExecuted(
        uint256 minAmount,
        uint256 maxAmount
    ) public {
        expectCall_feesManager_setMinAndMaxTxFee(minAmount, maxAmount);

        vm.prank(bridgeMediator);
        tokenManager.updateFeeAmountRange(
            FeeAmountRangeOpMessage({minimumAmount: minAmount, maximumAmount: maxAmount})
        );
    }

    //-------------------
    // `fixReleaseTokensMessage` tests
    //-------------------

    function test_fixReleaseTokensMessage_revertsWhen_messageNotFixable(bytes32 messageId) public {
        mockCall_bridgeMediator_messageReverted(messageId, false);

        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, messageId)
        );

        tokenManager.fixReleaseTokensMessage(messageId);
    }

    function test_fixReleaseTokensMessage_sendsMessage(
        bytes32 fixingMessageId,
        bytes32 fixMessageId
    ) public {
        mockCall_bridgeMediator_messageReverted(fixingMessageId, true);

        bytes memory data = abi.encodeCall(
            ITokenizationRecovery.fixReleaseTokensMessage,
            (fixingMessageId)
        );
        expectCall_bridgeMediator_sendMessage(data, fixMessageId);

        vm.expectEmit(address(tokenManager));
        emit FixReleaseTokensMessageSend(fixingMessageId, fixMessageId);

        vm.prank(bridgeMediator);
        tokenManager.fixReleaseTokensMessage(fixingMessageId);
    }

    //-------------------
    // `fixBurnTokensMessage` tests
    //-------------------

    function test_fixBurnTokensMessage_revertsWhen_messageNotFixable(bytes32 messageId) public {
        mockCall_bridgeMediator_messageReverted(messageId, false);

        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, messageId)
        );

        tokenManager.fixBurnTokensMessage(messageId);
    }

    function test_fixBurnTokensMessage_sendsMessage(
        bytes32 fixingMessageId,
        bytes32 fixMessageId
    ) public {
        mockCall_bridgeMediator_messageReverted(fixingMessageId, true);

        bytes memory data = abi.encodeCall(
            IRedemptionRecovery.fixBurnTokensMessage,
            (fixingMessageId)
        );
        expectCall_bridgeMediator_sendMessage(data, fixMessageId);

        vm.expectEmit(address(tokenManager));
        emit FixBurnTokensMessageSend(fixingMessageId, fixMessageId);

        vm.prank(bridgeMediator);
        tokenManager.fixBurnTokensMessage(fixingMessageId);
    }

    //-------------------
    // `fixRefundTokensMessage` tests
    //-------------------

    function test_fixRefundTokensMessage_revertsWhen_messageNotFixable(bytes32 messageId) public {
        mockCall_bridgeMediator_messageReverted(messageId, false);

        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, messageId)
        );

        tokenManager.fixRefundTokensMessage(messageId);
    }

    function test_fixRefundTokensMessage_sendsMessage(
        bytes32 fixingMessageId,
        bytes32 fixMessageId
    ) public {
        mockCall_bridgeMediator_messageReverted(fixingMessageId, true);

        bytes memory data = abi.encodeCall(
            IRedemptionRecovery.fixRefundTokensMessage,
            (fixingMessageId)
        );
        expectCall_bridgeMediator_sendMessage(data, fixMessageId);

        vm.expectEmit(address(tokenManager));
        emit FixRefundTokensMessageSend(fixingMessageId, fixMessageId);

        vm.prank(bridgeMediator);
        tokenManager.fixRefundTokensMessage(fixingMessageId);
    }

    //-------------------
    // `fixOpsMessage` tests
    //-------------------

    function test_fixOpsMessage_revertsWhen_messageNotFixable(bytes32 messageId) public {
        mockCall_bridgeMediator_messageReverted(messageId, false);

        vm.expectRevert(
            abi.encodeWithSelector(BridgeInteractor.MessageNotFixable.selector, messageId)
        );

        tokenManager.fixOpsMessage(OpType.Transfer, messageId);
    }

    function test_fixOpsMessage_sendsMessage(bytes32 fixingMessageId, bytes32 fixMessageId) public {
        OpType opType = OpType.Transfer;

        mockCall_bridgeMediator_messageReverted(fixingMessageId, true);
        bytes memory data = abi.encodeCall(IOpsRecovery.fixMessage, (fixingMessageId));
        expectCall_bridgeMediator_sendMessage(data, fixMessageId);

        vm.expectEmit(address(tokenManager));
        emit OpFixMessageSend(opType, fixingMessageId, fixMessageId);

        vm.prank(bridgeMediator);
        tokenManager.fixOpsMessage(opType, fixingMessageId);
    }

    //-------------------
    // `toTokenAmount` tests
    //-------------------

    function test_toTokenAmount_properlyConverted(uint48 weight, uint256 decimals) public {
        vm.assume(decimals <= 18);

        mockCall_token_decimals(decimals);

        assertEq(
            tokenManager.toTokenAmount(MetalToken(token), weight),
            (uint256(weight) * (10 ** decimals))
        );
    }
}

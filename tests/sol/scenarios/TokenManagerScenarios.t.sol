// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BaseTest} from "tests/sol/BaseTest.t.sol";
import {TokenManager} from "contracts/management/TokenManager.sol";
import {BridgeMediator} from "agau-common-bridge/BridgeMediator.sol";

import {OpType} from "agau-common/admin-ops/OpsTypes.sol";
import {
    CommonTokenOpMessage,
    BurnTokenOpMessage,
    TokenManagementOpMessage,
    TokenTransferOpMessage,
    CreateFeeDiscountGroupOpMessage,
    TransactionFeeRateOpMessage,
    FeeAmountRangeOpMessage,
    UpdateFeeDiscountGroupOpMessage,
    UserDiscountGroupOpMessage
} from "agau-common-bridge/BridgeTypes.sol";
import {DiscountType, Discount} from "agau-common/admin-ops/WhitelistTypes.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract TokenManager_InitSetup is BaseTest {
    using Strings for uint256;

    // Copied from TokenManager.sol
    event TokenBurnCallbackSend(bytes32 indexed messageId);
    event FixReleaseTokensMessageSend(
        bytes32 indexed fixingMessageId,
        bytes32 indexed fixMessageId
    );
    event FixRefundTokensMessageSend(bytes32 indexed fixingMessageId, bytes32 indexed fixMessageId);
    event FixBurnTokensMessageSend(bytes32 indexed fixingMessageId, bytes32 indexed fixMessageId);
    event OpFixMessageSend(
        OpType indexed opType,
        bytes32 indexed fixingMessageId,
        bytes32 indexed fixMessageId
    );

    function testSkip() public virtual override {}

    function _generateCommonTokenOpMessages(
        uint256 numOfMessages,
        uint48 weightPerMessage
    ) internal returns (CommonTokenOpMessage[] memory messages) {
        messages = new CommonTokenOpMessage[](numOfMessages);

        for (uint256 i; i < numOfMessages; ++i) {
            messages[i] = CommonTokenOpMessage({
                account: makeAddr(string.concat("account_", i.toString())),
                weight: weightPerMessage,
                metalId: TOKEN_ID
            });
        }
    }

    function _generateBurnTokenOpMessages(
        CommonTokenOpMessage[] memory message
    ) internal pure returns (BurnTokenOpMessage[] memory messages) {
        uint256 numOfMessages = message.length;
        messages = new BurnTokenOpMessage[](numOfMessages);

        for (uint256 i; i < numOfMessages; ++i) {
            messages[i] = BurnTokenOpMessage({
                weight: message[i].weight,
                metalId: message[i].metalId
            });
        }
    }

    function _generateTokenManagementOpMessage(
        CommonTokenOpMessage memory message
    ) internal view returns (TokenManagementOpMessage memory) {
        return
            TokenManagementOpMessage({
                user: message.account,
                metalId: message.metalId,
                amount: _tokenManager.toTokenAmount(_token, message.weight)
            });
    }

    function _generateTokenTransferOpMessage(
        TokenManagementOpMessage memory tokenMngMessage
    ) internal returns (TokenTransferOpMessage memory message) {
        message = TokenTransferOpMessage({
            from: tokenMngMessage.user,
            to: makeAddr("to"),
            metalId: tokenMngMessage.metalId,
            amount: tokenMngMessage.amount
        });
    }

    function _generateTokenTransferOpMessage(
        CommonTokenOpMessage memory commonMessage
    ) internal returns (TokenTransferOpMessage memory message) {
        message = TokenTransferOpMessage({
            from: address(_tokenManager),
            to: makeAddr("to"),
            metalId: commonMessage.metalId,
            amount: _tokenManager.toTokenAmount(_token, commonMessage.weight)
        });
    }

    function _generateCreateDiscountGroupMessage()
        internal
        view
        returns (CreateFeeDiscountGroupOpMessage memory message)
    {
        message = CreateFeeDiscountGroupOpMessage({
            groupType: TX_GROUP_TYPE,
            discount: Discount({value: DISCOUNT_VALUE, discountType: DISCOUNT_TYPE})
        });
    }

    function _generateTransactionFeeRateMessage(
        uint256 feeRate
    ) internal pure returns (TransactionFeeRateOpMessage memory message) {
        message = TransactionFeeRateOpMessage({feeRate: feeRate});
    }

    function _generateFeeAmountRangeMessage(
        uint256 minAmount,
        uint256 maxAmount
    ) internal pure returns (FeeAmountRangeOpMessage memory message) {
        message = FeeAmountRangeOpMessage({minimumAmount: minAmount, maximumAmount: maxAmount});
    }
}

abstract contract TokenManager_TokensMintedAndLocked_SingleMessage is TokenManager_InitSetup {
    CommonTokenOpMessage[] internal _commonMsgs;

    function setUp() public virtual override {
        super.setUp();

        _commonMsgs = _generateCommonTokenOpMessages(1, WEIGHT);

        vm.prank(address(_bridgeMediator));
        _tokenManager.mintAndLockTokens(_commonMsgs);
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_TokensMintedAndLocked_MultipleMessages is TokenManager_InitSetup {
    CommonTokenOpMessage[] internal _commonMsgs;

    function setUp() public virtual override {
        super.setUp();

        _commonMsgs = _generateCommonTokenOpMessages(_testsConfig.numOfMessages, WEIGHT);

        vm.prank(address(_bridgeMediator));
        _tokenManager.mintAndLockTokens(_commonMsgs);
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_TokensReleased_SingleMessage is
    TokenManager_TokensMintedAndLocked_SingleMessage
{
    function setUp() public virtual override {
        super.setUp();

        vm.prank(address(_bridgeMediator));
        _tokenManager.releaseTokens(_commonMsgs);
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_TokensReleased_MultipleMessages is
    TokenManager_TokensMintedAndLocked_MultipleMessages
{
    function setUp() public virtual override {
        super.setUp();

        vm.prank(address(_bridgeMediator));
        _tokenManager.releaseTokens(_commonMsgs);
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_TokensFrozen is TokenManager_TokensReleased_SingleMessage {
    TokenManagementOpMessage internal _tokenManagementMsg;

    function setUp() public virtual override {
        super.setUp();

        _tokenManagementMsg = _generateTokenManagementOpMessage(_commonMsgs[0]);

        vm.prank(address(_bridgeMediator));
        _tokenManager.freezeTokens(_tokenManagementMsg);
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_TokensReceivedForRedemption_SingleMessage is
    TokenManager_TokensReleased_SingleMessage
{
    function setUp() public virtual override {
        super.setUp();

        address from = _commonMsgs[0].account;
        uint256 amount = _tokenManager.toTokenAmount(_token, _commonMsgs[0].weight);

        vm.prank(from);
        _token.transfer(address(_tokenManager), amount);
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_TokensReceivedForRedemption_MultipleMessages is
    TokenManager_TokensReleased_MultipleMessages
{
    function setUp() public virtual override {
        super.setUp();

        for (uint256 i; i < _commonMsgs.length; ++i) {
            address from = _commonMsgs[i].account;
            uint256 amount = _tokenManager.toTokenAmount(_token, _commonMsgs[i].weight);

            vm.prank(from);
            _token.transfer(address(_tokenManager), amount);
        }
    }

    function testSkip() public virtual override {}
}

abstract contract TokenManager_FeeDiscountGroupCreated is TokenManager_InitSetup {
    uint256 internal _discountGroupId;

    function setUp() public virtual override {
        super.setUp();

        CreateFeeDiscountGroupOpMessage memory message = _generateCreateDiscountGroupMessage();

        vm.prank(address(_bridgeMediator));
        _tokenManager.createDiscountGroup(message);
        _discountGroupId = _feesManager.discountGroupCount(TX_GROUP_TYPE);
    }

    function _generateUpdateDiscountGroupMessage()
        internal
        view
        returns (UpdateFeeDiscountGroupOpMessage memory message)
    {
        return _generateUpdateDiscountGroupMessage(DISCOUNT_VALUE, DISCOUNT_TYPE);
    }

    function _generateUpdateDiscountGroupMessage(
        uint248 discountValue,
        DiscountType discountType
    ) internal view returns (UpdateFeeDiscountGroupOpMessage memory message) {
        message = UpdateFeeDiscountGroupOpMessage({
            groupType: TX_GROUP_TYPE,
            discount: Discount({value: discountValue, discountType: discountType}),
            groupId: _discountGroupId
        });
    }

    function _generateUserDiscountGroupMessage()
        internal
        view
        returns (UserDiscountGroupOpMessage memory message)
    {
        message = UserDiscountGroupOpMessage({
            groupType: TX_GROUP_TYPE,
            groupId: _discountGroupId,
            user: USER_1
        });
    }

    function testSkip() public virtual override {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// import "@openzeppelin/contracts/access/AccessControl.sol";

import {MultiSigValidation} from "../signature/SignatureValidation.sol";
import {AuthorizationGuardAccess} from "./roles/AuthorizationGuardAccess.sol";
import {MetalToken} from "../token/MetalToken.sol";
import {TokenFactory} from "../token/TokenFactory.sol";
import {FeesManager} from "./FeesManager.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {OpsTypes} from "lib/agau-common/admin-ops/OpsTypes.sol";
// import {
//     CommonTokenOpMessage,
//     BurnTokenOpMessage,
//     TransactionFeeRateOpMessage,
//     TokenManagementOpMessage,
//     TokenTransferOpMessage,
//     CreateFeeDiscountGroupOpMessage,
//     UpdateFeeDiscountGroupOpMessage,
//     UserDiscountGroupOpMessage,
//     FeeAmountRangeOpMessage
// } from "lib/agau-types/BridgeTypes.sol";

import {BridgeTypes} from "lib/agau-types/BridgeTypes.sol";

import {ITokenManager} from "lib/agau-common/tokens-management/interface/ITokenManager.sol";
import {IFeesWhitelistManager} from "lib/agau-common/admin-ops/interface/IFeesWhitelistManager.sol";

import {
    ITokenizationRecovery
} from "lib/agau-common/tokens-management/tokenization/interface/ITokenizationRecovery.sol";

import {
    IRedemptionCallback
} from "lib/agau-common/tokens-management/redemption/interface/IRedemptionCallback.sol";
import {
    IRedemptionRecovery
} from "lib/agau-common/tokens-management/redemption/interface/IRedemptionRecovery.sol";
import {IOpsRecovery} from "lib/agau-common/admin-ops/interface/IOpsRecovery.sol";

/**
 * @title TokenManager
 * @author
 * @dev Contract that manages tokens contracts.
 *      based on the messages from the other side of the bridge. Also, its used as the
 *      redemption wallet, meaning the user should send their tokens here to redeem them
 *      for a physical asset.
 */
contract TokenManager is AuthorizationGuardAccess, ITokenManager, IFeesWhitelistManager {
    using SafeERC20 for MetalToken;

    /// @dev `TokenFactory` contract
    TokenFactory private immutable _tokenFactory;
    /// @dev `FeesManager` contract
    FeesManager private immutable _feesManager;

    MultiSigValidation private _multiSigValidation;

    /// @dev mapping for message status
    mapping(bytes32 => bool) private messageExecuted; // added

    // bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    /// @dev Emitted when the `TokenBurnCallbackSend` message is sent
    /// @param messageId Identifier of the message
    event TokenBurnCallbackSend(bytes32 indexed messageId);

    /// @dev Emitted when the `fixReleaseTokens` message is sent
    /// @param fixingMessageId Identifier of the message  that is being fixed
    /// @param fixMessageId Identifier of the fix message send
    event FixReleaseTokensMessageSend(
        bytes32 indexed fixingMessageId,
        bytes32 indexed fixMessageId
    );

    /// @dev Emitted when the `fixBurnTokens` message is sent
    /// @param fixingMessageId Identifier of the message that is being fixed
    /// @param fixMessageId Identifier of the fix message send
    event FixBurnTokensMessageSend(bytes32 indexed fixingMessageId, bytes32 indexed fixMessageId);

    /// @dev Emitted when the `fixRefundTokens` message is sent
    /// @param fixingMessageId Identifier of the message  that is being fixed
    /// @param fixMessageId Identifier of the fix message send
    event FixRefundTokensMessageSend(bytes32 indexed fixingMessageId, bytes32 indexed fixMessageId);

    /// @dev Emitted when message for fixing admin operation is send
    /// @param opType Operation type
    /// @param fixingMessageId Message identifier of the fixed messsage
    /// @param fixMessageId Message identifier of the send fix message
    event OpFixMessageSend(
        OpsTypes.OpType indexed opType,
        bytes32 indexed fixingMessageId,
        bytes32 indexed fixMessageId
    );

    /// @dev Triggered when message with `messageId` is not executed
    /// @param messageId Identifier of the message
    error MessageNotExecuted(bytes32 messageId);

    /// @param tokenFactory_ The address of `TokenFactory` contract
    /// @param feesManager_ The address of `FeesManager` contract
    constructor(
        address tokenFactory_,
        address feesManager_,
        address[] memory admins_,
        address[] memory authorizedAccounts_,
        address multiSigValidationAddress_,
        address authorizationGuardAddress_
    ) {
        _tokenFactory = TokenFactory(tokenFactory_);
        _feesManager = FeesManager(feesManager_);
        // _authorizationGuard = AuthorizationGuard(authorizationGuardAddress_);
        _multiSigValidation = MultiSigValidation(multiSigValidationAddress_);

        __AuthorizationGuardAccess_init(authorizationGuardAddress_);
    }

    /// @inheritdoc ITokenManager
    function mintAndLockTokens(
        BridgeTypes.CommonTokenOpMessage[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            bytes32 _hash = keccak256(
                abi.encodePacked(
                    "mintAndLockTokens",
                    messages[i].account,
                    messages[i].weight,
                    messages[i].metalId
                )
            );
            bytes32 prefixedHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
            require(prefixedHash == messages[i].signatureHash, "Invalid hash");

            // Validate submitted signatures using the MultiSigValidation contract
            require(
                _multiSigValidation.validateSignatures(
                    prefixedHash,
                    messages[i].signatures,
                    messages[i].roleIndices
                ),
                "Invalid signatures"
            );

            MetalToken token = _tokenFactory.tokenForId(messages[i].metalId);
            token.mintAndLock(messages[i].account, toTokenAmount(token, messages[i].weight));
        }
    }

    /// @inheritdoc ITokenManager
    function releaseTokens(
        BridgeTypes.CommonTokenOpMessage[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            MetalToken token = _tokenFactory.tokenForId(messages[i].metalId);
            token.release(messages[i].account, toTokenAmount(token, messages[i].weight));
        }
    }

    /// @inheritdoc ITokenManager
    function burnTokens(
        BridgeTypes.BurnTokenOpMessage[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            MetalToken token = _tokenFactory.tokenForId(messages[i].metalId);
            token.burn(address(this), toTokenAmount(token, messages[i].weight));
        }
    }

    // /// @dev Sends message to execute `onTokensBurned` callback on the other side of the bridge
    // ///      Emits `TokenBurnCallbackSend` event
    // /// @param messageId Identifier of the message resulting in tokens burn
    // function executeBurnTokensCallback(bytes32 messageId) external {
    //     if (!messageExecuted[messageId]) revert MessageNotExecuted(messageId);
    //     // Sending a callback to the other side of the bridge
    //     _sendMessage(abi.encodeCall(IRedemptionCallback.onTokensBurned, messageId));

    //     emit TokenBurnCallbackSend(messageId);
    // }

    /// @inheritdoc ITokenManager
    function refundTokens(
        BridgeTypes.CommonTokenOpMessage[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            MetalToken token = _tokenFactory.tokenForId(messages[0].metalId);
            token.safeTransfer(messages[i].account, toTokenAmount(token, messages[i].weight));
        }
    }

    /// @inheritdoc ITokenManager
    function freezeTokens(
        BridgeTypes.TokenManagementOpMessage calldata message
    ) external onlyAuthorizedAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.lock(message.user, message.amount);
    }

    /// @inheritdoc ITokenManager
    function unfreezeTokens(
        BridgeTypes.TokenManagementOpMessage calldata message
    ) external onlyAuthorizedAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.unlock(message.user, message.amount);
    }

    /// @inheritdoc ITokenManager
    function seizeTokens(
        BridgeTypes.TokenTransferOpMessage calldata message
    ) external onlyAuthorizedAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.seizeLocked(message.from, message.to, message.amount);
    }

    /// @inheritdoc ITokenManager
    function transferTokens(
        BridgeTypes.TokenTransferOpMessage calldata message
    ) external onlyAuthorizedAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.safeTransfer(message.to, message.amount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function createDiscountGroup(
        BridgeTypes.CreateFeeDiscountGroupOpMessage calldata message
    ) external onlyAuthorizedAccess {
        _feesManager.createDiscountGroup(message.groupType, message.discount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateDiscountGroup(
        BridgeTypes.UpdateFeeDiscountGroupOpMessage calldata message
    ) external onlyAuthorizedAccess {
        _feesManager.updateDiscountGroup(message.groupType, message.groupId, message.discount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function setUserDiscountGroup(
        BridgeTypes.UserDiscountGroupOpMessage calldata message
    ) external onlyAuthorizedAccess {
        _feesManager.setGroupForUser(message.groupType, message.groupId, message.user);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateTransactionFeeRate(
        BridgeTypes.TransactionFeeRateOpMessage calldata message
    ) external onlyAuthorizedAccess {
        _feesManager.setTxFeeRate(message.feeRate);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateFeeAmountRange(
        BridgeTypes.FeeAmountRangeOpMessage calldata message
    ) external onlyAuthorizedAccess {
        _feesManager.setMinAndMaxTxFee(message.minimumAmount, message.maximumAmount);
    }

    // /// @dev Fixes `releaseTokens` message on L2 in case of the execution failure
    // ///      Emits `FixReleaseTokensMessageSend` event
    // /// @param messageId Identifier of the message on this side of the bridge to fix
    // function fixReleaseTokensMessage(bytes32 messageId) external {
    //     _revertIfMessageNotFixable(messageId);

    //     bytes32 sendMessageId = _sendMessage(
    //         abi.encodeCall(ITokenizationRecovery.fixReleaseTokensMessage, messageId)
    //     );

    //     emit FixReleaseTokensMessageSend(messageId, sendMessageId);
    // }

    // /// @dev Fixes `burnTokens` message on L2 in case of the execution failure
    // ///      Emits `FixBurnTokensMessageSend` event
    // /// @param messageId Identifier of the message on this side of the bridge to fix
    // function fixBurnTokensMessage(bytes32 messageId) external {
    //     _revertIfMessageNotFixable(messageId);

    //     bytes32 sendMessageId = _sendMessage(
    //         abi.encodeCall(IRedemptionRecovery.fixBurnTokensMessage, messageId)
    //     );

    //     emit FixBurnTokensMessageSend(messageId, sendMessageId);
    // }

    // /// @dev Fixes `refundTokens` message on L2 in case of the execution failure
    // ///      Emits `FixRefundTokensMessageSend` event
    // /// @param messageId Identifier of the message on this side of the bridge to fix
    // function fixRefundTokensMessage(bytes32 messageId) external {
    //     _revertIfMessageNotFixable(messageId);

    //     bytes32 sendMessageId = _sendMessage(
    //         abi.encodeCall(IRedemptionRecovery.fixRefundTokensMessage, messageId)
    //     );

    //     emit FixRefundTokensMessageSend(messageId, sendMessageId);
    // }

    // /// @dev Fixes admin operation message on L2 in case of the execution failure
    // ///      Emits `OpFixMessageSend` event
    // /// @param opType Operation type
    // /// @param messageId Identifier of the message on this side of the bridge to fix
    // function fixOpsMessage(OpsTypes.OpType opType, bytes32 messageId) external {
    //     _revertIfMessageNotFixable(messageId);

    //     bytes32 sendMessageId = _sendMessage(abi.encodeCall(IOpsRecovery.fixMessage, messageId));

    //     emit OpFixMessageSend(opType, messageId, sendMessageId);
    // }

    /// @dev Returns the address of the `TokenFactory` contract
    /// @return `TokenFactory` contract address
    function tokenFactory() external view returns (address) {
        return address(_tokenFactory);
    }

    /// @dev Returns the address of the `FeesManager` contract
    /// @return `FeesManager` contract address
    function feesManager() external view returns (address) {
        return address(_feesManager);
    }

    /// @dev Converts the weight to the token amount
    /// @param weight The weight to convert
    /// @return The token amount
    function toTokenAmount(MetalToken token, uint48 weight) public view returns (uint256) {
        return uint256(weight) * 10 ** token.decimals();
    }
}

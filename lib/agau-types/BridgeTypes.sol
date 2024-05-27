// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {WhitelistTypes} from "lib/agau-common/admin-ops/WhitelistTypes.sol";

/**
 * @title BridgeTypes
 * @author
 * @dev Library with types used in by the contracts on L1 side of the bridge
 */
library BridgeTypes {
    /// @dev Structure containing common token management message data
    struct CommonTokenOpMessage {
        // Account address message is referred to
        address account;
        // Total amount of the metal (in grams)
        uint48 weight;
        // Metal identifier
        uint8 metalId;
        // Message Hash
        bytes32 signatureHash;
        // Submitted signatures
        bytes[] signatures;
        // Signer index in roles array
        uint256[] roleIndices;
    }

    /// @dev Structure containing token burn message data
    struct BurnTokenOpMessage {
        // Total amount of the metal (in grams)
        uint48 weight;
        // Metal identifier
        uint8 metalId;
    }

    /// @dev Structure containing token management message data
    struct TokenManagementOpMessage {
        // Account address message is referred to
        address user;
        // Amount of tokens
        uint256 amount;
        // Metal identifier
        uint8 metalId;
    }

    /// @dev Structure containing token seize message data
    struct TokenTransferOpMessage {
        // Account address whose tokens will be seized
        address from;
        // Address to which seized tokens will be moved
        address to;
        // Amount of tokens transferred
        uint256 amount;
        // Metal identifier
        uint8 metalId;
    }

    /// @dev Structure containing create fee discount group message data
    struct CreateFeeDiscountGroupOpMessage {
        // Discount group type
        WhitelistTypes.GroupType groupType;
        // Discount group configuration
        WhitelistTypes.Discount discount;
    }

    /// @dev Structure containing update fee discount group message data
    struct UpdateFeeDiscountGroupOpMessage {
        // Discount group type
        WhitelistTypes.GroupType groupType;
        // Discount group configuration
        WhitelistTypes.Discount discount;
        // Discount group id
        uint256 groupId;
    }

    /// @dev Structure containing assign group to a user message data
    struct UserDiscountGroupOpMessage {
        // Discount group type
        WhitelistTypes.GroupType groupType;
        // Discount group id
        uint256 groupId;
        // User address
        address user;
    }

    /// @dev Structure containing transaction fee rate message data
    struct TransactionFeeRateOpMessage {
        // Transaction fee rate
        uint256 feeRate;
    }

    /// @dev Structure containing fee amount range message data
    struct FeeAmountRangeOpMessage {
        // Minimum amount of the fee
        uint256 minimumAmount;
        // Maximum amount of the fee
        uint256 maximumAmount;
    }
}

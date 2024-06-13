// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {TokenOpTypes} from "../../../agau-types/TokenOpTypes.sol";

/**
 * @title ITokenManager
 * @author
 * @dev Interface of the `TokenManager` contract.
 *
 */
interface ITokenManager {
    /// @dev Mints and locks the tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function mintAndLockTokens(TokenOpTypes.CommonTokenOpWithSignature[] memory messages) external;

    /// @dev Releases tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function releaseTokens(TokenOpTypes.CommonTokenOpWithSignature[] memory messages) external;

    /// @dev Burns tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function burnTokens(TokenOpTypes.BurnTokenOp[] memory messages) external;

    /// @dev Refunds tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function refundTokens(TokenOpTypes.CommonTokenOp[] memory messages) external;

    /// @dev Freezes tokens based on the data provided via `message`.
    /// @param message The message being passed
    function freezeTokens(TokenOpTypes.TokenManagementOp memory message) external;

    /// @dev Unfreezes tokens based on the data provided via `message`.
    /// @param message The message being passed
    function unfreezeTokens(TokenOpTypes.TokenManagementOp memory message) external;

    /// @dev Seizes tokens based on the data provided via `message`.
    /// @param message The message being passed
    function seizeTokens(TokenOpTypes.TokenTransferOp memory message) external;

    /// @dev Transfers tokens based on the data provided via `message`.
    /// @param message The message being passed
    function transferTokens(TokenOpTypes.TokenTransferOp memory message) external;
}

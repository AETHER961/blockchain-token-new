// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BridgeTypes} from "../../../agau-types/BridgeTypes.sol";

/**
 * @title ITokenManager
 * @author
 * @dev Interface of the `TokenManager` contract on the other side of the bridge.
 *      The destination contract specified when sending a message to the bridge must implement this interface.
 */
interface ITokenManager {
    /// @dev Mints and locks the tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function mintAndLockTokens(BridgeTypes.CommonTokenOpMessage[] memory messages) external;

    /// @dev Releases tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function releaseTokens(BridgeTypes.CommonTokenOpMessage[] memory messages) external;

    /// @dev Burns tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function burnTokens(BridgeTypes.BurnTokenOpMessage[] memory messages) external;

    /// @dev Refunds tokens based on the data provided via `messages`.
    /// @param messages The messages being passed
    function refundTokens(BridgeTypes.CommonTokenOpMessage[] memory messages) external;

    /// @dev Freezes tokens based on the data provided via `message`.
    /// @param message The message being passed
    function freezeTokens(BridgeTypes.TokenManagementOpMessage memory message) external;

    /// @dev Unfreezes tokens based on the data provided via `message`.
    /// @param message The message being passed
    function unfreezeTokens(BridgeTypes.TokenManagementOpMessage memory message) external;

    /// @dev Seizes tokens based on the data provided via `message`.
    /// @param message The message being passed
    function seizeTokens(BridgeTypes.TokenTransferOpMessage memory message) external;

    /// @dev Transfers tokens based on the data provided via `message`.
    /// @param message The message being passed
    function transferTokens(BridgeTypes.TokenTransferOpMessage memory message) external;
}

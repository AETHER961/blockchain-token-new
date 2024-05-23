// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title IRedemptionCallback
 * @author
 * @dev Interface containing methods for redemption process where callaback is required
 */
interface IRedemptionCallback {
    /// @dev Callback function executed after `burnTokens` message is executed
    ///      Callable only by mediator contract
    /// @param messageId Identifier of the message
    function onTokensBurned(bytes32 messageId) external;
}

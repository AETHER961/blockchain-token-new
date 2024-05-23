// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title IRedemptionRecovery
 * @author
 * @dev Interface containing methods for redemption and refund process recovery in case of bridge message failure
 */
interface IRedemptionRecovery {
    /// @dev Fixes `burnTokens` message in case of execution failure on L1
    /// @param messageId Identifier of the failed message
    function fixBurnTokensMessage(bytes32 messageId) external;

    /// @dev Fixes `refundTokens` message in case of execution failure on L1
    /// @param messageId Identifier of the failed message
    function fixRefundTokensMessage(bytes32 messageId) external;
}

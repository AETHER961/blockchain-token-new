// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title ITokenizationRecovery
 * @author
 * @dev Interface containing methods for tokenization process recovery in case of bridge message failure
 */
interface ITokenizationRecovery {
    /// @dev Fixes the state of the protocol in case of the `releaseTokens` message failure on L1
    /// @param messageId Identifier of the failed message
    function fixReleaseTokensMessage(bytes32 messageId) external;
}

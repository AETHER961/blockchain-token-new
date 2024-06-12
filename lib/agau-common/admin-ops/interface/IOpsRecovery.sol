// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * Deprecated
 * @title IOpsRecovery
 * @author
 * @dev Interface containing methods for admin ops processes recovery in case of bridge message failure
 */
interface IOpsRecovery {
    /// @dev Fixes admin ops message in case of execution failure on L1
    /// @param messageId Identifier of the failed message
    function fixMessage(bytes32 messageId) external;
}

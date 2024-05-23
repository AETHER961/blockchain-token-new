// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BridgeTypes} from "../../../agau-types/BridgeTypes.sol";

/**
 * @title IFeesWhitelistManager
 * @author
 * @dev Interface of the fees and whitelist manager contract on the foreign side of the bridge
 *      The destination contract specified when sending a message to the bridge must implement this interface.
 */
interface IFeesWhitelistManager {
    /// @dev Creates discount group based on the data provided via `message`.
    /// @param message The create discount group message
    function createDiscountGroup(
        BridgeTypes.CreateFeeDiscountGroupOpMessage memory message
    ) external;

    /// @dev Updates discount group based on the data provided via `message`.
    /// @param message The update discount group message
    function updateDiscountGroup(
        BridgeTypes.UpdateFeeDiscountGroupOpMessage memory message
    ) external;

    /// @dev Sets user's discount group based on the data provided via `message`.
    /// @param message The set user discount group message
    function setUserDiscountGroup(BridgeTypes.UserDiscountGroupOpMessage memory message) external;

    /// @dev Updates transaction fee rate based on the data provided via `message`.
    /// @param message The update transaction fee rate message
    function updateTransactionFeeRate(
        BridgeTypes.TransactionFeeRateOpMessage memory message
    ) external;

    /// @dev Updates fee amount range based on the data provided via `message`.
    /// @param message The update fee amount range message
    function updateFeeAmountRange(BridgeTypes.FeeAmountRangeOpMessage memory message) external;
}

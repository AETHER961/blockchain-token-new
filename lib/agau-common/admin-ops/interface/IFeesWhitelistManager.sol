// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {TokenOpTypes} from "../../../agau-types/TokenOpTypes.sol";

/**
 * @title IFeesWhitelistManager
 * @author
 * @dev Interface of the fees and whitelist manager contract.
 *
 */
interface IFeesWhitelistManager {
    /// @dev Creates discount group based on the data provided via `message`.
    /// @param message The create discount group message
    function createDiscountGroup(
        TokenOpTypes.CreateFeeDiscountGroupOpMessage memory message
    ) external;

    /// @dev Updates discount group based on the data provided via `message`.
    /// @param message The update discount group message
    function updateDiscountGroup(
        TokenOpTypes.UpdateFeeDiscountGroupOpMessage memory message
    ) external;

    /// @dev Sets user's discount group based on the data provided via `message`.
    /// @param message The set user discount group message
    function setUserDiscountGroup(TokenOpTypes.UserDiscountGroupOpMessage memory message) external;

    /// @dev Updates transaction fee rate based on the data provided via `message`.
    /// @param message The update transaction fee rate message
    function updateTransactionFeeRate(
        TokenOpTypes.TransactionFeeRateOpMessage memory message
    ) external;

    /// @dev Updates fee amount range based on the data provided via `message`.
    /// @param message The update fee amount range message
    function updateFeeAmountRange(TokenOpTypes.FeeAmountRangeOpMessage memory message) external;
}

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
    /// @dev Creates discount group based on the data provided via `instruction`.
    /// @param instruction The create discount group instruction
    function createDiscountGroup(TokenOpTypes.CreateFeeDiscountGroupOp memory instruction) external;

    /// @dev Updates discount group based on the data provided via `instruction`.
    /// @param instruction The update discount group instruction
    function updateDiscountGroup(TokenOpTypes.UpdateFeeDiscountGroupOp memory instruction) external;

    /// @dev Sets user's discount group based on the data provided via `instruction`.
    /// @param instruction The set user discount group instruction
    function setUserDiscountGroup(TokenOpTypes.UserDiscountGroupOp memory instruction) external;

    /// @dev Updates transaction fee rate based on the data provided via `instruction`.
    /// @param instruction The update transaction fee rate instruction
    function updateTransactionFeeRate(
        TokenOpTypes.TransactionFeeRateOp memory instruction
    ) external;

    /// @dev Updates fee amount range based on the data provided via `instruction`.
    /// @param instruction The update fee amount range instruction
    function updateFeeAmountRange(TokenOpTypes.FeeAmountRangeOp memory instruction) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title OpsTypes
 * @author
 * @dev Library containing common types regarding Ops for L2 and L1 contracts
 */
library OpsTypes {
    /// @dev Possible Operation types
    enum OpType {
        Freeze,
        Unfreeze,
        Seize,
        Transfer,
        CreateDiscountGroup,
        UpdateDiscountGroup,
        SetUserDiscountGroup,
        UpdateTransactionFeeRate,
        UpdateFeeAmountRange
    }
}

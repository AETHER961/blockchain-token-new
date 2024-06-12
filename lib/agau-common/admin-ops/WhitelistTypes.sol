// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title WhitelistTypes
 * @author
 * @dev Library with types used by the contracts.
 *      Used mainly for the discount groups operations and management
 */
library WhitelistTypes {
    /// @dev Denominator for the transfer fee
    ///      Min value 1 / 100000 = 0.001% (0.00001) Max value 100000 / 100000 = 100% (1)
    uint256 internal constant TX_FEE_DENOMINATOR = 100000; /// changed from  "internal" to "public"
    /// @dev Denominator for the discount value
    ///      Min value 1 / 1000000 = 0.0001% (0.000001) Max value 1000000 / 1000000 = 100% (1)
    uint256 internal constant DISCOUNT_RATE_DENOMINATOR = 1000000;

    /// @dev Structure for storing discount data
    struct Discount {
        // Discount type
        DiscountType discountType;
        // Percent value of discount
        uint248 value;
    }

    /// @dev Possible discount group types
    enum GroupType {
        // Non-set group
        None,
        // Fiat percent tx group
        TxFee
    }

    /// @dev Possible discount types
    enum DiscountType {
        // No discount
        None,
        // Flat percent fee instead of calculated fee
        FlatPercentFee,
        // Percent discount on calculated fee
        PercentDiscount
    }
}

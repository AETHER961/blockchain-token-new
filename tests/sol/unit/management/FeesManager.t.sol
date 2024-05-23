// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {BaseCallGuard} from "agau-common/common/BaseCallGuard.sol";
import {FeesManager} from "contracts/management/FeesManager.sol";

import {CallGuardHelper} from "agau-common-test/unit/helpers/CallGuardHelper.t.sol";
import {
    TX_FEE_DENOMINATOR,
    DISCOUNT_RATE_DENOMINATOR,
    WhitelistGroupType,
    DiscountType,
    Discount
} from "agau-common/admin-ops/WhitelistTypes.sol";
import {ArrayUtils} from "agau-common/common/ArrayUtils.sol";

contract FeesManagerTest is Test, CallGuardHelper {
    FeesManager public feesManager;
    address feesWallet = makeAddr("feesWallet");
    address zeroFeeAccount = makeAddr("zeroFeeAccount");
    address user_1 = makeAddr("user_1");
    address user_2 = makeAddr("user_2");

    // Copied from FeesManager.sol
    event FeesWalletSet(address indexed newFeeWallet);

    function setUp() public {
        feesManager = new FeesManager();
        feesManager.initialize(
            feesWallet,
            0,
            0,
            type(uint256).max,
            ArrayUtils.asAddressArray(1, zeroFeeAccount)
        );
        feesManager.setAuthorized(authorized, true);
    }

    //----------------
    // `initialize` test
    //----------------

    function test_initialize_properSetup() public {
        uint256 txFeeRate = 0;
        uint256 minTxFee = 0;
        uint256 maxTxFee = type(uint256).max;

        feesManager = new FeesManager();
        feesManager.initialize(
            feesWallet,
            txFeeRate,
            minTxFee,
            maxTxFee,
            ArrayUtils.asAddressArray(1, zeroFeeAccount)
        );

        assertEq(feesManager.owner(), address(this));
        assertEq(feesManager.feesWallet(), feesWallet);
        assertEq(feesManager.txFeeRate(), txFeeRate);
        assertEq(feesManager.minTxFee(), minTxFee);
        assertEq(feesManager.maxTxFee(), maxTxFee);
        assertEq(
            feesManager.discountGroupIdForUser(WhitelistGroupType.TxFee, zeroFeeAccount),
            feesManager.SPECIAL_AGAU_GROUP_ID()
        );
    }

    //---------------
    // `setFeeWallet` test
    //---------------

    function test_setFeesWallet_revertsWhen_senderNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        feesManager.setFeesWallet(address(0));
    }

    function test_setFeesWallet_revertsWhen_feesWalletZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(FeesManager.InvalidNewFeesWallet.selector));

        vm.prank(authorized);
        feesManager.setFeesWallet(address(0));
    }

    function test_setFeesWallet_properSetup(address newFeesWallet) public {
        vm.assume(newFeesWallet != address(0));

        vm.expectEmit(address(feesManager));
        emit FeesWalletSet(newFeesWallet);

        vm.prank(authorized);
        feesManager.setFeesWallet(newFeesWallet);

        assertEq(feesManager.feesWallet(), newFeesWallet);
    }

    //---------------
    // `calculateTxFee` test
    //---------------

    function test_calculateTxFee_noDiscounts_returnsProperValue(
        uint256 txFeeRate,
        uint256 amount
    ) public {
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);
        if (txFeeRate != 0) vm.assume(amount < type(uint256).max / txFeeRate);

        vm.prank(authorized);
        feesManager.setTxFeeRate(txFeeRate);

        assertEq(
            feesManager.calculateTxFee(user_1, user_2, amount),
            feesManager.calculateTxFee(amount)
        );
    }

    function test_calculateTxFee_participantsInSpecialGroup_returnsProperValue(
        uint256 amount
    ) public {
        uint256 specialGroupId = feesManager.SPECIAL_AGAU_GROUP_ID();

        vm.prank(authorized);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, specialGroupId, user_1);

        // In case sender is in special group, no fee should be charged
        assertEq(feesManager.calculateTxFee(user_1, user_2, amount), 0);

        vm.startPrank(authorized);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, 0, user_1);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, specialGroupId, user_2);
        vm.stopPrank();

        // In case receiver is in special group, no fee should be charged
        assertEq(feesManager.calculateTxFee(user_1, user_2, amount), 0);
    }

    function test_calculateTxFee_participantsInFlatPercentFeeDiscountGroup_returnsProperValue(
        uint248 flatTxFeeRate,
        uint256 amount
    ) public {
        vm.assume(flatTxFeeRate <= TX_FEE_DENOMINATOR);
        // Bound `amount` value to prevent overflow
        if (flatTxFeeRate != 0) vm.assume(amount < type(uint256).max / flatTxFeeRate);

        vm.startPrank(authorized);
        feesManager.createDiscountGroup(
            WhitelistGroupType.TxFee,
            Discount({discountType: DiscountType.FlatPercentFee, value: flatTxFeeRate})
        );
        uint256 discountGroupId = feesManager.discountGroupCount(WhitelistGroupType.TxFee);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, discountGroupId, user_1);
        vm.stopPrank();

        // In case sender is in some discount group, his discount should apply
        assertEq(
            feesManager.calculateTxFee(user_1, user_2, amount),
            (amount * flatTxFeeRate) / DISCOUNT_RATE_DENOMINATOR
        );

        vm.startPrank(authorized);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, 0, user_1);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, discountGroupId, user_2);
        vm.stopPrank();

        // In case receiver is in some discount group, discount should not apply
        assertEq(
            feesManager.calculateTxFee(user_1, user_2, amount),
            (amount * feesManager.txFeeRate()) / TX_FEE_DENOMINATOR
        );
    }

    function test_calculateTxFee_participantsInPercentDiscountGroup_returnsProperValue(
        uint248 discountRate,
        uint256 txFeeRate,
        uint256 amount
    ) public {
        vm.assume(discountRate <= DISCOUNT_RATE_DENOMINATOR);
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);

        // Bound `amount` value to prevent overflow
        if (discountRate != 0) vm.assume(amount < type(uint256).max / discountRate);
        if (txFeeRate != 0) vm.assume(amount < type(uint256).max / txFeeRate);

        vm.startPrank(authorized);
        feesManager.setTxFeeRate(txFeeRate);
        feesManager.createDiscountGroup(
            WhitelistGroupType.TxFee,
            Discount({discountType: DiscountType.PercentDiscount, value: discountRate})
        );
        uint256 discountGroupId = feesManager.discountGroupCount(WhitelistGroupType.TxFee);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, discountGroupId, user_1);
        vm.stopPrank();

        uint256 expectedDiscount = (feesManager.calculateTxFee(amount) * discountRate) /
            DISCOUNT_RATE_DENOMINATOR;

        // In case sender is in discount group, his discount should apply
        assertEq(
            feesManager.calculateTxFee(user_1, user_2, amount),
            feesManager.calculateTxFee(amount) - expectedDiscount
        );

        vm.startPrank(authorized);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, 0, user_1);
        feesManager.setGroupForUser(WhitelistGroupType.TxFee, discountGroupId, user_2);
        vm.stopPrank();

        // In case receiver is in discount group, discount should not apply
        assertEq(
            feesManager.calculateTxFee(user_1, user_2, amount),
            feesManager.calculateTxFee(amount)
        );
    }

    function test_calculateTxFee_feeSmallerThanMinValueSet_returnsProperValue(
        uint256 txFeeRate,
        uint256 amount
    ) public {
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);
        // Bound `amount` value to prevent overflow
        if (txFeeRate != 0) vm.assume(amount < type(uint256).max / txFeeRate);

        vm.startPrank(authorized);
        feesManager.setTxFeeRate(txFeeRate);
        uint256 expectedFee = feesManager.calculateTxFee(user_1, user_2, amount);
        uint256 minFee = expectedFee + 1;
        feesManager.setMinAndMaxTxFee(minFee, type(uint256).max);

        assertEq(feesManager.calculateTxFee(user_1, user_2, amount), minFee);
    }

    function test_calculateTxFee_feeBiggerThanMaxValueSet_returnsProperValue(
        uint256 txFeeRate,
        uint256 amount
    ) public {
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);
        // Bound `amount` value to prevent overflow
        if (txFeeRate != 0) vm.assume(amount < type(uint256).max / txFeeRate);

        vm.startPrank(authorized);
        feesManager.setTxFeeRate(txFeeRate);
        uint256 expectedFee = feesManager.calculateTxFee(user_1, user_2, amount);
        uint256 maxValue = expectedFee > 0 ? expectedFee - 1 : 0;
        feesManager.setMinAndMaxTxFee(maxValue, maxValue);

        assertEq(feesManager.calculateTxFee(user_1, user_2, amount), maxValue);
    }

    //----------------
    // `feesWallet` test
    //----------------

    function test_feesWallet_properSetup(address feesWallet_) public {
        vm.assume(feesWallet_ != address(0));

        assertEq(feesManager.feesWallet(), feesWallet);

        vm.prank(authorized);
        feesManager.setFeesWallet(feesWallet_);

        assertEq(feesManager.feesWallet(), feesWallet_);
    }
}

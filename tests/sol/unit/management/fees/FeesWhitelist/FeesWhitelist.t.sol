// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {BaseCallGuard} from "agau-common/common/BaseCallGuard.sol";
import {FeesWhitelist} from "contracts/management/fees/FeesWhitelist.sol";
import {
    FeesWhitelistExposed
} from "tests/sol/unit/management/fees/FeesWhitelist/FeesWhitelistExposed.t.sol";

import {CallGuardHelper} from "agau-common-test/unit/helpers/CallGuardHelper.t.sol";
import {
    WhitelistGroupType,
    DiscountType,
    Discount,
    DISCOUNT_RATE_DENOMINATOR
} from "agau-common/admin-ops/WhitelistTypes.sol";

contract FeesWhitelistTest is Test, CallGuardHelper {
    FeesWhitelistExposed public feesWhitelist;
    address zeroFeeAccount = makeAddr("zeroFeeAccount");

    // Copied from FeesWhitelist.sol
    event DiscountGroupCreated(
        WhitelistGroupType indexed groupType,
        uint256 indexed groupId,
        Discount discount
    );
    event DiscountGroupUpdated(
        WhitelistGroupType indexed groupType,
        uint256 indexed groupId,
        Discount discount
    );
    event UserToFeeGroupSet(
        WhitelistGroupType indexed groupType,
        address indexed user,
        uint256 indexed groupId
    );

    function setUp() public {
        feesWhitelist = new FeesWhitelistExposed();

        address[] memory zeroFeesAccounts = new address[](1);
        zeroFeesAccounts[0] = zeroFeeAccount;
        feesWhitelist.initialize(zeroFeesAccounts);
        feesWhitelist.setAuthorized(authorized, true);
    }

    function _createDiscountGroup(
        WhitelistGroupType groupType,
        Discount memory discount
    ) internal returns (uint256) {
        vm.prank(authorized);
        feesWhitelist.createDiscountGroup(groupType, discount);

        return feesWhitelist.discountGroupCount(groupType);
    }

    //-------------------------
    // `__FeesWhitelist_init` function
    //-------------------------

    function test_FeesWhitelist_init_specialTxFeeDiscountGroupCreated_assignedToZeroFeeAccount()
        public
    {
        feesWhitelist = new FeesWhitelistExposed();
        address[] memory zeroFeesAccounts = new address[](1);
        zeroFeesAccounts[0] = zeroFeeAccount;
        feesWhitelist.initialize(zeroFeesAccounts);

        Discount memory discount = feesWhitelist.discount(
            WhitelistGroupType.TxFee,
            feesWhitelist.SPECIAL_AGAU_GROUP_ID()
        );

        assertEq(uint8(discount.discountType), uint8(DiscountType.PercentDiscount));
        assertEq(uint248(discount.value), uint248(DISCOUNT_RATE_DENOMINATOR));
        assertEq(
            feesWhitelist.discountGroupIdForUser(WhitelistGroupType.TxFee, zeroFeeAccount),
            feesWhitelist.SPECIAL_AGAU_GROUP_ID()
        );

        discount = feesWhitelist.discountForUser(WhitelistGroupType.TxFee, zeroFeeAccount);

        assertEq(uint8(discount.discountType), uint8(DiscountType.PercentDiscount));
        assertEq(uint248(discount.value), uint248(DISCOUNT_RATE_DENOMINATOR));
    }

    //-------------------------
    // `createDiscountGroup` function
    //-------------------------

    function test_createDiscountGroup_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        feesWhitelist.createDiscountGroup(
            WhitelistGroupType.None,
            Discount({discountType: DiscountType.None, value: 0})
        );
    }

    function test_createDiscountGroup_revertsWhen_invalidDiscountType() public {
        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.InvalidDiscountType.selector));

        vm.prank(authorized);
        feesWhitelist.createDiscountGroup(
            WhitelistGroupType.None,
            Discount({discountType: DiscountType.None, value: 0})
        );
    }

    function test_createDiscountGroup_revertsWhen_invalidDiscountValue() public {
        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.InvalidDiscountValue.selector));

        vm.prank(authorized);
        feesWhitelist.createDiscountGroup(
            WhitelistGroupType.TxFee,
            Discount({
                discountType: DiscountType.PercentDiscount,
                value: uint248(DISCOUNT_RATE_DENOMINATOR) + 1
            })
        );
    }

    function test_createDiscountGroup_createsNewDiscountGroup() public {
        uint248 discountValue = uint248(DISCOUNT_RATE_DENOMINATOR);
        DiscountType dType = DiscountType.PercentDiscount;
        Discount memory discount = Discount({discountType: dType, value: discountValue});
        WhitelistGroupType gType = WhitelistGroupType.TxFee;
        uint256 groupCount = feesWhitelist.discountGroupCount(gType);

        vm.expectEmit(address(feesWhitelist));
        emit DiscountGroupCreated(gType, groupCount + 1, discount);

        vm.prank(authorized);
        feesWhitelist.createDiscountGroup(gType, discount);

        assertEq(feesWhitelist.discountGroupCount(gType), groupCount + 1);
        discount = feesWhitelist.discount(gType, groupCount + 1);
        assertEq(uint8(discount.discountType), uint8(dType));
        assertEq(uint248(discount.value), discountValue);
    }

    //-------------------------
    // `updateDiscountGroup` function
    //-------------------------

    function test_updateDiscountGroup_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        feesWhitelist.updateDiscountGroup(
            WhitelistGroupType.None,
            0,
            Discount({discountType: DiscountType.None, value: 0})
        );
    }

    function test_updateDiscountGroup_revertsWhen_discountGroupNotExist(uint256 groupId) public {
        vm.assume(groupId != 0 && groupId != feesWhitelist.SPECIAL_AGAU_GROUP_ID());
        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.DiscountGroupNotExist.selector));

        vm.prank(authorized);
        feesWhitelist.updateDiscountGroup(
            WhitelistGroupType.TxFee,
            groupId,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );
    }

    function test_updateDiscountGroup_revertsWhen_defaultDiscountGroup() public {
        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.CannotChangeDefaultGroup.selector));

        vm.prank(authorized);
        feesWhitelist.updateDiscountGroup(
            WhitelistGroupType.TxFee,
            0,
            Discount({discountType: DiscountType.None, value: 0})
        );
    }

    function test_updateDiscountGroup_revertsWhen_invalidDiscountType() public {
        uint256 groupId = _createDiscountGroup(
            WhitelistGroupType.TxFee,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );

        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.InvalidDiscountType.selector));

        vm.prank(authorized);
        feesWhitelist.updateDiscountGroup(
            WhitelistGroupType.TxFee,
            groupId,
            Discount({discountType: DiscountType.None, value: 0})
        );
    }

    function test_updateDiscountGroup_revertsWhen_invalidDiscountValue() public {
        uint256 groupId = _createDiscountGroup(
            WhitelistGroupType.TxFee,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );
        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.InvalidDiscountValue.selector));

        vm.prank(authorized);
        feesWhitelist.updateDiscountGroup(
            WhitelistGroupType.TxFee,
            groupId,
            Discount({
                discountType: DiscountType.PercentDiscount,
                value: uint248(DISCOUNT_RATE_DENOMINATOR) + 1
            })
        );
    }

    function test_updateDiscountGroup_updatesDiscountGroup(uint248 updatedDiscountValue) public {
        vm.assume(updatedDiscountValue != 0 && updatedDiscountValue <= DISCOUNT_RATE_DENOMINATOR);
        WhitelistGroupType gType = WhitelistGroupType.TxFee;
        uint256 groupId = _createDiscountGroup(
            gType,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );

        Discount memory updatedDiscount = Discount({
            discountType: DiscountType.PercentDiscount,
            value: updatedDiscountValue
        });

        vm.expectEmit(address(feesWhitelist));
        emit DiscountGroupUpdated(gType, groupId, updatedDiscount);

        vm.prank(authorized);
        feesWhitelist.updateDiscountGroup(gType, groupId, updatedDiscount);

        Discount memory discount = feesWhitelist.discount(WhitelistGroupType.TxFee, groupId);

        assertEq(uint8(discount.discountType), uint8(updatedDiscount.discountType));
        assertEq(uint248(discount.value), updatedDiscount.value);
    }

    //-------------------------
    // `setGroupForUser` function
    //-------------------------

    function test_setGroupForUser_revertsWhen_senderNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        feesWhitelist.setGroupForUser(WhitelistGroupType.None, 0, address(0));
    }

    function test_setGroupForUser_revertsWhen_groupNotExist(uint256 groupId) public {
        vm.assume(groupId != 0 && groupId != feesWhitelist.SPECIAL_AGAU_GROUP_ID());
        vm.expectRevert(abi.encodeWithSelector(FeesWhitelist.DiscountGroupNotExist.selector));

        vm.prank(authorized);
        feesWhitelist.setGroupForUser(WhitelistGroupType.TxFee, groupId, address(0));
    }

    function test_setGroupForUser_setsGroupForUser() public {
        WhitelistGroupType gType = WhitelistGroupType.TxFee;
        uint256 groupId = _createDiscountGroup(
            gType,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );

        vm.expectEmit(address(feesWhitelist));
        emit UserToFeeGroupSet(gType, zeroFeeAccount, groupId);

        vm.prank(authorized);
        feesWhitelist.setGroupForUser(gType, groupId, zeroFeeAccount);

        assertEq(feesWhitelist.discountGroupIdForUser(gType, zeroFeeAccount), groupId);
    }

    //-------------------------
    // `discount` function
    //-------------------------

    function test_discount_returnsProperValues(uint256 groupId) public {
        vm.assume(groupId != feesWhitelist.SPECIAL_AGAU_GROUP_ID());
        WhitelistGroupType gType = WhitelistGroupType.TxFee;
        Discount memory discount = feesWhitelist.discount(gType, groupId);

        assertEq(uint8(discount.discountType), uint8(DiscountType.None));
        assertEq(uint248(discount.value), uint248(0));

        uint256 groupId_ = _createDiscountGroup(
            gType,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );

        discount = feesWhitelist.discount(gType, groupId_);

        assertEq(uint8(discount.discountType), uint8(DiscountType.PercentDiscount));
        assertEq(uint248(discount.value), uint248(0));
    }

    //-------------------------
    // `discountGroupCount` function
    //-------------------------

    function test_discountGroupCount_returnsProperValues() public {
        uint256 groupCount = feesWhitelist.discountGroupCount(WhitelistGroupType.TxFee);
        assertEq(groupCount, 1);

        _createDiscountGroup(
            WhitelistGroupType.TxFee,
            Discount({discountType: DiscountType.PercentDiscount, value: 0})
        );

        assertEq(feesWhitelist.discountGroupCount(WhitelistGroupType.TxFee), groupCount + 1);
    }

    //-------------------------
    // `discountGroupIdForUser` function
    //-------------------------

    function test_discountGroupIdForUser_returnsProperValues(address user) public {
        vm.assume(user != zeroFeeAccount);

        assertEq(feesWhitelist.discountGroupIdForUser(WhitelistGroupType.TxFee, user), 0);

        uint256 specialGroupId = feesWhitelist.SPECIAL_AGAU_GROUP_ID();

        vm.prank(authorized);
        feesWhitelist.setGroupForUser(WhitelistGroupType.TxFee, specialGroupId, user);

        assertEq(
            feesWhitelist.discountGroupIdForUser(WhitelistGroupType.TxFee, user),
            specialGroupId
        );
    }

    //-------------------------
    // `discountForUser` function
    //-------------------------

    function test_discountForUser_returnsProperValues(address user) public {
        vm.assume(user != zeroFeeAccount);

        Discount memory discount = feesWhitelist.discountForUser(WhitelistGroupType.TxFee, user);

        assertEq(uint8(discount.discountType), uint8(DiscountType.None));
        assertEq(uint248(discount.value), uint248(0));

        uint256 specialGroupId = feesWhitelist.SPECIAL_AGAU_GROUP_ID();

        vm.prank(authorized);
        feesWhitelist.setGroupForUser(WhitelistGroupType.TxFee, specialGroupId, user);

        discount = feesWhitelist.discountForUser(WhitelistGroupType.TxFee, user);

        assertEq(uint8(discount.discountType), uint8(DiscountType.PercentDiscount));
        assertEq(uint248(discount.value), uint248(DISCOUNT_RATE_DENOMINATOR));
    }

    //-------------------------
    // `discountForTxParticipants` function
    //-------------------------

    function test_discountForTxParticipants_returnsProperValue_anyParticipantInSpecialGroup(
        address user_1,
        address user_2
    ) public {
        vm.assume(user_1 != zeroFeeAccount && user_2 != zeroFeeAccount);

        WhitelistGroupType gType = WhitelistGroupType.TxFee;

        Discount memory discount;
        uint256 denominator;

        (discount, denominator) = feesWhitelist.discountForTxParticipants(gType, user_1, user_2);

        assertEq(uint8(discount.discountType), uint8(DiscountType.None));
        assertEq(uint248(discount.value), 0);

        (discount, denominator) = feesWhitelist.discountForTxParticipants(
            gType,
            user_1,
            zeroFeeAccount
        );

        assertEq(uint8(discount.discountType), uint8(DiscountType.PercentDiscount));
        assertEq(uint248(discount.value), uint248(DISCOUNT_RATE_DENOMINATOR));

        (discount, denominator) = feesWhitelist.discountForTxParticipants(
            gType,
            zeroFeeAccount,
            user_2
        );

        assertEq(uint8(discount.discountType), uint8(DiscountType.PercentDiscount));
        assertEq(uint248(discount.value), uint248(DISCOUNT_RATE_DENOMINATOR));
    }
}

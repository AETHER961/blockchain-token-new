// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {FeesManager} from "contracts/management/FeesManager.sol";
import {TxFeeManager} from "contracts/management/fees/TxFeeManager.sol";
import {FeesWhitelist} from "contracts/management/fees/FeesWhitelist.sol";

import {WhitelistGroupType, Discount} from "agau-common/admin-ops/WhitelistTypes.sol";

abstract contract FeesManagerMock is Test {
    address public feesManager = makeAddr("feesManager");
    address feesWallet = makeAddr("feesWallet");

    function mockCall_feesManager_feesWallet() internal {
        vm.mockCall(
            feesManager,
            abi.encodeWithSelector(FeesManager.feesWallet.selector),
            abi.encode(feesWallet)
        );
    }

    function mockCall_feesManager_calculateTxFee(
        address from,
        address to,
        uint256 amount,
        uint256 result
    ) internal {
        vm.mockCall(
            feesManager,
            abi.encodeWithSelector(FeesManager.calculateTxFee.selector, from, to, amount),
            abi.encode(result)
        );
    }

    function expectCall_feesManager_createDiscountGroup(
        WhitelistGroupType groupType,
        Discount memory discount
    ) internal {
        bytes memory data = abi.encodeCall(
            FeesWhitelist.createDiscountGroup,
            (groupType, discount)
        );

        vm.mockCall(feesManager, data, abi.encode());
        vm.expectCall(feesManager, data);
    }

    function expectCall_feesManager_updateDiscountGroup(
        WhitelistGroupType groupType,
        Discount memory discount,
        uint256 groupId
    ) internal {
        bytes memory data = abi.encodeCall(
            FeesWhitelist.updateDiscountGroup,
            (groupType, groupId, discount)
        );

        vm.mockCall(feesManager, data, abi.encode());
        vm.expectCall(feesManager, data);
    }

    function expectCall_feesManager_setGroupForUser(
        WhitelistGroupType groupType,
        uint256 groupId,
        address user
    ) internal {
        bytes memory data = abi.encodeCall(
            FeesWhitelist.setGroupForUser,
            (groupType, groupId, user)
        );

        vm.mockCall(feesManager, data, abi.encode());
        vm.expectCall(feesManager, data);
    }

    function expectCall_feesManager_setTxFeeRate(uint256 txFeeRate) internal {
        bytes memory data = abi.encodeCall(TxFeeManager.setTxFeeRate, (txFeeRate));

        vm.mockCall(feesManager, data, abi.encode());
        vm.expectCall(feesManager, data);
    }

    function expectCall_feesManager_setMinAndMaxTxFee(
        uint256 minAmount,
        uint256 maxAmount
    ) internal {
        bytes memory data = abi.encodeCall(TxFeeManager.setMinAndMaxTxFee, (minAmount, maxAmount));

        vm.mockCall(feesManager, data, abi.encode());
        vm.expectCall(feesManager, data);
    }

    function testSkip() public virtual {}
}

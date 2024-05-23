// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {BaseCallGuard} from "agau-common/common/BaseCallGuard.sol";
import {TxFeeManager} from "contracts/management/fees/TxFeeManager.sol";
import {
    TxFeeManagerExposed
} from "tests/sol/unit/management/fees/TxFeeManager/TxFeeManagerExposed.t.sol";

import {CallGuardHelper} from "agau-common-test/unit/helpers/CallGuardHelper.t.sol";
import {TX_FEE_DENOMINATOR} from "agau-common/admin-ops/WhitelistTypes.sol";

contract TxFeeManagerTest is Test, CallGuardHelper {
    TxFeeManagerExposed public txFeeManager;

    // Copied from TxFeeManager.sol
    event TxFeeRateSet(uint256 indexed newTxFeeRate);
    event MinAndMaxTxFeeSet(uint256 indexed minTxFee, uint256 indexed maxTxFee);

    function setUp() public {
        txFeeManager = new TxFeeManagerExposed();
        txFeeManager.initialize(0, 0, 0);
        txFeeManager.setAuthorized(authorized, true);
    }

    //-------------
    // `__TxFeeManager_init` function
    //-------------

    function test_TxFeeManager_init_revertsWhen_txFeeRateInvalid(uint256 txFeeRate) public {
        vm.assume(txFeeRate > TX_FEE_DENOMINATOR);

        txFeeManager = new TxFeeManagerExposed();

        vm.expectRevert(abi.encodeWithSelector(TxFeeManager.InvalidTxFeeRate.selector));

        txFeeManager.initialize(txFeeRate, 0, 0);
    }

    function test_TxFeeManager_init_revertsWhen_minTxFeeGreaterThanMaxTxFee(
        uint256 minTxFee,
        uint256 maxTxFee
    ) public {
        vm.assume(minTxFee > maxTxFee);

        txFeeManager = new TxFeeManagerExposed();

        vm.expectRevert(abi.encodeWithSelector(TxFeeManager.InvalidMinOrMaxTxValue.selector));

        txFeeManager.initialize(0, minTxFee, maxTxFee);
    }

    function test_TxFeeManager_init_properlySetup(
        uint256 txFeeRate,
        uint256 minTxFee,
        uint256 maxTxFee
    ) public {
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);
        vm.assume(minTxFee <= maxTxFee);

        txFeeManager = new TxFeeManagerExposed();
        txFeeManager.initialize(txFeeRate, minTxFee, maxTxFee);

        assertEq(txFeeManager.txFeeRate(), txFeeRate);
        assertEq(txFeeManager.minTxFee(), minTxFee);
        assertEq(txFeeManager.maxTxFee(), maxTxFee);
    }

    //-------------
    // `setTxFeeRate` function
    //-------------

    function test_setTxFeeRate_revertsWhen_senderNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        txFeeManager.setTxFeeRate(0);
    }

    function test_setTxFeeRate_revertsWhen_txFeeRateInvalid(uint256 txFeeRate) public {
        vm.assume(txFeeRate > TX_FEE_DENOMINATOR);

        vm.expectRevert(abi.encodeWithSelector(TxFeeManager.InvalidTxFeeRate.selector));

        vm.prank(authorized);
        txFeeManager.setTxFeeRate(txFeeRate);
    }

    function test_setTxFeeRate_properlySetup(uint256 txFeeRate) public {
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);

        vm.expectEmit(address(txFeeManager));
        emit TxFeeRateSet(txFeeRate);

        vm.prank(authorized);
        txFeeManager.setTxFeeRate(txFeeRate);

        assertEq(txFeeManager.txFeeRate(), txFeeRate);
    }

    //-------------
    // `setMinAndMaxTxFee` function
    //-------------

    function test_setMinAndMaxTxFee_revertsWhen_senderNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        txFeeManager.setMinAndMaxTxFee(0, 0);
    }

    function test_setMinAndMaxTxFee_revertsWhen_minTxFeeGreaterThanMaxTxFee(
        uint256 minTxFee,
        uint256 maxTxFee
    ) public {
        vm.assume(minTxFee > maxTxFee);

        vm.expectRevert(abi.encodeWithSelector(TxFeeManager.InvalidMinOrMaxTxValue.selector));

        vm.prank(authorized);
        txFeeManager.setMinAndMaxTxFee(minTxFee, maxTxFee);
    }

    function test_setMinAndMaxTxFee_properlySetup(uint256 minTxFee, uint256 maxTxFee) public {
        vm.assume(minTxFee <= maxTxFee);

        vm.expectEmit(address(txFeeManager));
        emit MinAndMaxTxFeeSet(minTxFee, maxTxFee);

        vm.prank(authorized);
        txFeeManager.setMinAndMaxTxFee(minTxFee, maxTxFee);

        assertEq(txFeeManager.minTxFee(), minTxFee);
        assertEq(txFeeManager.maxTxFee(), maxTxFee);
    }

    //-------------
    // `calculateTxFee` function
    //-------------

    function test_calculateTxFee_properValueReturned(uint256 amount, uint256 txFeeRate) public {
        // Constrain the amount to prevent overflow. This value shouln't be reached anyway in reality
        vm.assume(amount < type(uint256).max / TX_FEE_DENOMINATOR);
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);

        assertEq(txFeeManager.calculateTxFee(amount), 0);

        vm.prank(authorized);
        txFeeManager.setTxFeeRate(txFeeRate);

        assertEq(txFeeManager.calculateTxFee(amount), (amount * txFeeRate) / TX_FEE_DENOMINATOR);
    }

    //-------------
    // `txFeeRate` function
    //-------------

    function test_txFeeRate_properValueReturned(uint256 txFeeRate) public {
        vm.assume(txFeeRate <= TX_FEE_DENOMINATOR);

        assertEq(txFeeManager.txFeeRate(), 0);

        vm.prank(authorized);
        txFeeManager.setTxFeeRate(txFeeRate);

        assertEq(txFeeManager.txFeeRate(), txFeeRate);
    }

    //-------------
    // `minTxFee` function
    //-------------

    function test_minTxFee_properValueReturned(uint256 minTxFee, uint256 maxTxFee) public {
        vm.assume(minTxFee <= maxTxFee);

        assertEq(txFeeManager.minTxFee(), 0);

        vm.prank(authorized);
        txFeeManager.setMinAndMaxTxFee(minTxFee, maxTxFee);

        assertEq(txFeeManager.minTxFee(), minTxFee);
    }

    //-------------
    // `maxTxFee` function
    //-------------

    function test_maxTxFee_properValueReturned(uint256 maxTxFee) public {
        assertEq(txFeeManager.maxTxFee(), 0);

        vm.prank(authorized);
        txFeeManager.setMinAndMaxTxFee(0, maxTxFee);

        assertEq(txFeeManager.maxTxFee(), maxTxFee);
    }
}

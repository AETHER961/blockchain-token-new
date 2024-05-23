// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {MetalToken} from "contracts/token/MetalToken.sol";

import {FeesManager} from "contracts/management/FeesManager.sol";
import {FeesManagerMock} from "tests/sol/unit/mocks/FeesManagerMock.t.sol";

import {CallGuardHelper} from "agau-common-test/unit/helpers/CallGuardHelper.t.sol";

import {BaseCallGuard} from "agau-common/common/BaseCallGuard.sol";
import {ArrayUtils} from "agau-common/common/ArrayUtils.sol";

contract MetalTokenTest is Test, CallGuardHelper, FeesManagerMock {
    MetalToken public token;
    address user_1 = makeAddr("user_1");
    address user_2 = makeAddr("user_2");

    function setUp() public {
        token = new MetalToken();
        token.initialize(address(this), feesManager, "Metal", "MTL");
        token.setAuthorized(authorized, true);
    }

    function testSkip() public virtual override(CallGuardHelper, FeesManagerMock) {}

    //----------------
    // `initialize` tests
    //----------------

    function test_initialize_properlySetup() public {
        string memory name = "Gold";
        string memory symbol = "GLD";

        token = new MetalToken();
        token.initialize(address(this), feesManager, name, symbol);

        assertEq(token.owner(), address(this));
        assertEq(token.feesManager(), feesManager);
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
    }

    //----------------
    // `mintAndLock` tests
    //----------------

    function test_mintAndLock_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        token.mintAndLock(address(0), 0);
    }

    function test_mintAndLock_mintsAndLocksTokens(uint256 amount) public {
        vm.prank(authorized);
        token.mintAndLock(user_1, amount);

        assertEq(token.balanceOf(user_1), 0);
        assertEq(token.lockedBalanceOf(user_1), amount);
    }

    //----------------
    // `release` tests
    //----------------

    function test_release_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        token.release(address(0), 0);
    }

    function test_release_tokensProperlyReleased(uint256 amount) public {
        assertEq(token.balanceOf(user_1), 0);

        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.release(user_1, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user_1), amount);
    }

    //----------------
    // `burn` tests
    //----------------

    function test_burn_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        token.burn(address(0), 0);
    }

    function test_burn_tokensProperlyBurned(uint256 amount) public {
        assertEq(token.balanceOf(user_1), 0);

        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.release(user_1, amount);
        token.burn(user_1, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user_1), 0);
    }

    //----------------
    // `seizeLocked` tests
    //----------------

    function test_seizeLocked_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        token.seizeLocked(address(0), address(0), 0);
    }

    function test_seizeLocked_tokensProperlySeized(uint256 amount) public {
        assertEq(token.balanceOf(user_1), 0);

        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.seizeLocked(user_1, user_2, amount);
        vm.stopPrank();

        assertEq(token.balanceOf(user_1), 0);
        assertEq(token.balanceOf(user_2), amount);
    }

    //----------------
    // `transfer` tests
    //----------------

    function test_transfer_revertsWhen_insuficientAvailableBalanceOfSender() public {
        uint256 balance = token.balanceOf(user_1);
        uint256 sendAmount = balance + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                MetalToken.InsufficientAvailableBalance.selector,
                user_1,
                balance,
                sendAmount
            )
        );

        vm.prank(user_1);
        token.transfer(user_2, sendAmount);
    }

    function test_transfer_transferSuccessful_txFeeZero(uint256 amount) public {
        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.release(user_1, amount);
        vm.stopPrank();

        mockCall_feesManager_feesWallet();
        mockCall_feesManager_calculateTxFee(user_1, user_2, amount, 0);

        vm.prank(user_1);
        token.transfer(user_2, amount);

        assertEq(token.balanceOf(user_1), 0);
        assertEq(token.balanceOf(user_2), amount);
        assertEq(token.balanceOf(feesWallet), 0);
    }

    function test_transfer_transferSuccessful_txFeeNotZero(uint256 amount, uint256 fee) public {
        vm.assume(amount >= fee);

        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.release(user_1, amount);
        vm.stopPrank();

        mockCall_feesManager_feesWallet();
        mockCall_feesManager_calculateTxFee(user_1, user_2, amount, fee);

        vm.prank(user_1);
        token.transfer(user_2, amount);

        assertEq(token.balanceOf(user_1), 0);
        assertEq(token.balanceOf(user_2), amount - fee);
        assertEq(token.balanceOf(feesWallet), fee);
    }

    //----------------
    // `transferFrom` tests
    //----------------

    function test_transferFrom_revertsWhen_insuficientAvailableBalanceOfSender() public {
        uint256 balance = token.balanceOf(user_1);
        uint256 sendAmount = balance + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                MetalToken.InsufficientAvailableBalance.selector,
                user_1,
                balance,
                sendAmount
            )
        );

        vm.prank(user_1);
        token.transferFrom(user_1, user_2, sendAmount);
    }

    function test_transferFrom_transferSuccessful_txFeeZero(uint256 amount) public {
        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.release(user_1, amount);
        vm.stopPrank();

        mockCall_feesManager_feesWallet();
        mockCall_feesManager_calculateTxFee(user_1, user_2, amount, 0);

        vm.prank(user_1);
        token.transferFrom(user_1, user_2, amount);

        assertEq(token.balanceOf(user_1), 0);
        assertEq(token.balanceOf(user_2), amount);
        assertEq(token.balanceOf(feesWallet), 0);
    }

    function test_transferFrom_transferSuccessful_txFeeNotZero(uint256 amount, uint256 fee) public {
        vm.assume(amount >= fee);

        vm.startPrank(authorized);
        token.mintAndLock(user_1, amount);
        token.release(user_1, amount);
        vm.stopPrank();

        mockCall_feesManager_feesWallet();
        mockCall_feesManager_calculateTxFee(user_1, user_2, amount, fee);

        vm.prank(user_1);
        token.transferFrom(user_1, user_2, amount);

        assertEq(token.balanceOf(user_1), 0);
        assertEq(token.balanceOf(user_2), amount - fee);
        assertEq(token.balanceOf(feesWallet), fee);
    }

    //----------------
    // `balanceOf` tests
    //----------------

    function test_balanceOf_returnsProperValue(uint256 amount) public {
        assertEq(token.balanceOf(user_1), 0);

        vm.prank(authorized);
        token.mintAndLock(user_1, amount);

        assertEq(token.balanceOf(user_1), 0);

        vm.prank(authorized);
        token.release(user_1, amount);

        assertEq(token.balanceOf(user_1), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {
    TokensLockableExposed
} from "tests/sol/unit/token/extensions/TokensLockable/TokensLockableExposed.t.sol";
import {TokensLockable} from "contracts/token/extensions/TokensLockable.sol";

import {BaseCallGuard} from "agau-common/common/BaseCallGuard.sol";
import {CallGuardHelper} from "agau-common-test/unit/helpers/CallGuardHelper.t.sol";

contract TokensLockableTest is Test, CallGuardHelper {
    TokensLockableExposed public tokensLockable;

    function setUp() public {
        tokensLockable = new TokensLockableExposed();
        tokensLockable.initialize();
        tokensLockable.setAuthorized(authorized, true);
    }

    // Copied from `TokensLockable.sol`
    event LockedBalanceChanged(address indexed account, uint256 lockedBalance);

    //---------------
    // `__TokensLockable_init` test
    //---------------

    function test_TokensLockable_init_properSetup() public {
        tokensLockable = new TokensLockableExposed();
        tokensLockable.initialize();

        assertEq(tokensLockable.owner(), address(this));
    }

    //-------------
    // `lock` function
    //-------------

    function test_lock_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        tokensLockable.lock(address(0), 0);
    }

    function test_lock_lockedBalanceUpdated(address account, uint256 amount) public {
        assertEq(tokensLockable.lockedBalanceOf(account), 0);

        vm.expectEmit(address(tokensLockable));
        emit LockedBalanceChanged(account, amount);

        vm.prank(authorized);
        tokensLockable.lock(account, amount);

        assertEq(tokensLockable.lockedBalanceOf(account), amount);
    }

    //---------------
    // `unlock` function
    //---------------

    function test_unlock_revertsWhen_callerNotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(BaseCallGuard.SenderNotAuthorized.selector));

        vm.prank(nonAuthorized);
        tokensLockable.unlock(address(0), 0);
    }

    function test_unlock_unlocksProperAmount(
        address account,
        uint256 lockedAmount,
        uint256 unlockAmount
    ) public {
        vm.assume(unlockAmount <= lockedAmount);

        vm.prank(authorized);
        tokensLockable.lock(account, lockedAmount);
        assertEq(tokensLockable.lockedBalanceOf(account), lockedAmount);


        uint256 expectedLockedBalance = lockedAmount - unlockAmount;

        vm.expectEmit(address(tokensLockable));
        emit LockedBalanceChanged(account, expectedLockedBalance);

        vm.prank(authorized);
        tokensLockable.unlock(account, unlockAmount);

        assertEq(tokensLockable.lockedBalanceOf(account), expectedLockedBalance);
    }

    //-------------
    // `lockedBalanceOf` function
    //-------------

    function test_lockedBalanceOf_returnsProperValue(address account, uint256 amount) public {
        assertEq(tokensLockable.lockedBalanceOf(account), 0);

        vm.prank(authorized);
        tokensLockable.lock(account, amount);

        assertEq(tokensLockable.lockedBalanceOf(account), amount);
    }
}

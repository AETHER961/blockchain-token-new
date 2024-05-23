// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {TokensLockable} from "contracts/token/extensions/TokensLockable.sol";
import {MetalToken} from "contracts/token/MetalToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract MetalTokenMock is Test {
    address public token = makeAddr("metalToken");

    function expectCall_token_mintAndLock(address account, uint256 amount) internal {
        bytes memory data = abi.encodeCall(MetalToken.mintAndLock, (account, amount));

        vm.mockCall(token, data, abi.encode());
        vm.expectCall(token, data);
    }

    function expectCall_token_release(address account, uint256 amount) internal {
        bytes memory data = abi.encodeCall(MetalToken.release, (account, amount));

        vm.mockCall(token, data, abi.encode());
        vm.expectCall(token, data);
    }

    function expectCall_token_transfer(address account, uint256 amount) internal {
        bytes memory data = abi.encodeCall(MetalToken.transfer, (account, amount));

        vm.mockCall(token, data, abi.encode(true));
        vm.expectCall(token, data);
    }

    function expectCall_token_burnTokens(address from, uint256 amount) internal {
        bytes memory data = abi.encodeCall(MetalToken.burn, (from, amount));

        vm.mockCall(token, data, abi.encode());
        vm.expectCall(token, data);
    }

    function mockCall_token_decimals(uint256 decimals) internal {
        vm.mockCall(token, abi.encodeCall(ERC20.decimals, ()), abi.encode(decimals));
    }

    function expectCall_token_lock(address account, uint256 amount) internal {
        bytes memory data = abi.encodeCall(TokensLockable.lock, (account, amount));

        vm.mockCall(token, data, abi.encode());
        vm.expectCall(token, data);
    }

    function expectCall_token_unlock(address account, uint256 amount) internal {
        bytes memory data = abi.encodeCall(TokensLockable.unlock, (account, amount));

        vm.mockCall(token, data, abi.encode());
        vm.expectCall(token, data);
    }

    function expectCall_token_seizeLocked(address from, address to, uint256 amount) internal {
        bytes memory data = abi.encodeCall(MetalToken.seizeLocked, (from, to, amount));

        vm.mockCall(token, data, abi.encode());
        vm.expectCall(token, data);
    }

    function testSkip() public virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BaseCallGuard} from "./BaseCallGuard.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title CallGuard
 * @author
 * @dev Defines the logic for restricted method calling.
 */
abstract contract CallGuard is BaseCallGuard, Ownable2Step {
    /// @param owner_ Owner address
    constructor(address owner_) Ownable(owner_) {}

    /// @dev Sets authorized status for `account` to `status`
    ///      Callable only by owner
    ///      Emits {AuthorizationStatusChanged} event
    /// @param account Account to change status for
    /// @param status New status
    function setAuthorized(address account, bool status) external override onlyOwner {
        _setAuthorized(account, status);
    }

    /// @dev Sets authorized status for `accounts` to `status`
    ///      Callable only by owner
    ///      Emits {AuthorizationStatusChanged} events
    /// @param accounts Accounts to change status for
    /// @param status New status
    function setAuthorizedBatch(
        address[] memory accounts,
        bool status
    ) external override onlyOwner {
        _setAuthorizedBatch(accounts, status);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BaseCallGuard} from "./BaseCallGuard.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    Ownable2StepUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/**
 * @title CallGuardUpgradeable
 * @author
 * @dev Upgradeable version of `CallGuard`. Defines the logic for restricted method calling.
 */
abstract contract CallGuardUpgradeable is BaseCallGuard, Ownable2StepUpgradeable {
    /// @dev Initializes the contract
    /// @param owner_ Owner address
    function __CallGuard_init(address owner_) internal onlyInitializing {
        __Ownable2Step_init();
        __Ownable_init(owner_);
    }

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

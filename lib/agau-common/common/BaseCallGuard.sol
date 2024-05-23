// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title BaseCallGuard
 * @author
 * @dev Defines the logic for restricted method calling.
 */
abstract contract BaseCallGuard {
    /// @dev Mapping from account to flag if authorized to execute restricted methods
    mapping(address account => bool authorized) private _authorized;

    /// @dev Emitted when authorization status for `account` is changed
    /// @param account Account for which status is changed
    /// @param status New status
    event AuthorizationStatusChanged(address indexed account, bool indexed status);

    /// Sender is not an authorized caller
    error SenderNotAuthorized();

    modifier onlyAuthorized() {
        if (!_authorized[msg.sender]) revert SenderNotAuthorized();
        _;
    }

    /// @dev Sets authorized status for `account` to `status`
    ///      Emits {AuthorizationStatusChanged} event
    /// @param account Account to change status for
    /// @param status New status
    function setAuthorized(address account, bool status) external virtual {
        _setAuthorized(account, status);
    }

    /// @dev Sets authorized status for `accounts` to `status`
    ///      Emits {AuthorizationStatusChanged} events
    /// @param accounts Accounts to change status for
    /// @param status New status
    function setAuthorizedBatch(address[] memory accounts, bool status) external virtual {
        _setAuthorizedBatch(accounts, status);
    }

    /// @dev Changes the authorized status for `account`
    ///      Emits {AuthorizationStatusChanged} event
    /// @param account Account to change status for
    /// @param status New status
    function _setAuthorized(address account, bool status) internal {
        _authorized[account] = status;
        emit AuthorizationStatusChanged(account, status);
    }

    /// @dev Changes the authorized status for `accounts`
    ///      Emits {AuthorizationStatusChanged} events
    /// @param accounts Accounts to change status for
    /// @param status New status
    function _setAuthorizedBatch(address[] memory accounts, bool status) internal {
        for (uint256 i; i < accounts.length; ++i) _setAuthorized(accounts[i], status);
    }

    /// @dev Returns the authorized status for `account`
    /// @param account Account to check status for
    /// @return Authorized status
    function authorized(address account) external view returns (bool) {
        return _authorized[account];
    }
}

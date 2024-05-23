// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * Deploy AuthorizationGuard first. Pass to the constructor the administrator addresses and the authorized addresses.
 * The admin addresses are able to make call general functions such as granting roles, revoking roles, etc..
 * The authorized addresses are able to call functions outside this contract which require authority such as
 * minting new tokens, burning, setting fees, etc..
 */
contract AuthorizationGuard is AccessControl {
    // bytes32 public constant override DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant AUTHORIZED_ROLE = keccak256("AUTHORIZED_ROLE");

    constructor(address[] memory admins, address[] memory authorizedAccounts) {
        /// Assign admin roles to admin accounts
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }

        /// Assign authorized roles to authorized accounts
        for (uint256 i = 0; i < authorizedAccounts.length; i++) {
            _grantRole(AUTHORIZED_ROLE, authorizedAccounts[i]);
        }
    }

    modifier onlyAdminAccess() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier onlyAuthorizedAccess() {
        require(hasRole(AUTHORIZED_ROLE, msg.sender), "Caller is not authorized");
        _;
    }

    function setAuthorized(address account, bool status) external onlyAdminAccess {
        if (status) {
            grantRole(AUTHORIZED_ROLE, account);
        } else {
            revokeRole(AUTHORIZED_ROLE, account);
        }
    }

    function setAuthorizedBatch(address[] memory accounts, bool status) external onlyAdminAccess {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (status) {
                grantRole(AUTHORIZED_ROLE, accounts[i]);
            } else {
                revokeRole(AUTHORIZED_ROLE, accounts[i]);
            }
        }
    }
}

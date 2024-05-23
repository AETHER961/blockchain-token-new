// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {FeesWhitelist} from "contracts/management/fees/FeesWhitelist.sol";

contract FeesWhitelistExposed is FeesWhitelist {
    function initialize(address[] memory zeroFeesAccounts) public initializer {
        super.__FeesWhitelist_init(zeroFeesAccounts);
        super.__CallGuard_init(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {TokensLockable} from "contracts/token/extensions/TokensLockable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokensLockableExposed is Initializable, TokensLockable {
    function initialize() external initializer {
        __TokensLockable_init();
        __CallGuard_init(msg.sender);
    }
}

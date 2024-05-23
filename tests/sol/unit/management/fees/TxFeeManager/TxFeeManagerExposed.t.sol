// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {TxFeeManager} from "contracts/management/fees/TxFeeManager.sol";

contract TxFeeManagerExposed is TxFeeManager {
    function initialize(
        uint256 txFeeRate_,
        uint256 minTxFee_,
        uint256 maxTxFee_
    ) public initializer {
        super.__TxFeeManager_init(txFeeRate_, minTxFee_, maxTxFee_);
        super.__CallGuard_init(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {FeesWhitelist} from "contracts/management/fees/FeesWhitelist.sol";
import {WhitelistGroupType, DiscountType} from "agau-common/admin-ops/WhitelistTypes.sol";

contract Constants is Test {
    // Overall
    address internal immutable OWNER = makeAddr("owner");
    address internal immutable AMB_CONTRACT = makeAddr("ambContract");
    address internal immutable USER_1 = makeAddr("user_1");
    address internal immutable USER_2 = makeAddr("user_2");

    // Token
    uint8 internal immutable TOKEN_ID = 0;
    uint256 internal immutable MINT_AMOUNT = 1e18;
    string internal NAME = "Gold";
    string internal SYMBOL = "GLD";

    // Fees Manager
    address internal immutable FEE_WALLET = makeAddr("feeWallet");
    uint256 internal immutable MIN_TX_FEE = 0;
    uint256 internal immutable MAX_TX_FEE = type(uint256).max;
    uint256 internal immutable TX_FEE_RATE = 1000;

    // Fees Whitelist
    address internal immutable ZERO_FEE_ACCOUNT = makeAddr("zeroFeeAccount");
    WhitelistGroupType internal immutable TX_GROUP_TYPE = WhitelistGroupType.TxFee;
    uint248 internal immutable DISCOUNT_VALUE = 1000;
    DiscountType internal immutable DISCOUNT_TYPE = DiscountType.PercentDiscount;

    // Token Manager
    uint48 internal immutable WEIGHT = 1000;
    bytes32 internal immutable RECEIVED_MESSAGE_ID = hex"01";
    bytes32 internal immutable SEND_MESSAGE_ID = hex"02";
}

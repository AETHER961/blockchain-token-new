// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {
    TokenManager_InitSetup,
    TokenManager_TokensMintedAndLocked_SingleMessage,
    TokenManager_TokensReceivedForRedemption_SingleMessage,
    TokenManager_TokensReleased_SingleMessage,
    TokenManager_TokensFrozen,
    TokenManager_FeeDiscountGroupCreated,
    TokenManager_TokensFrozen
} from "tests/sol/scenarios/TokenManagerScenarios.t.sol";

import {
    CommonTokenOpMessage,
    BurnTokenOpMessage,
    TokenManagementOpMessage,
    TokenTransferOpMessage,
    CreateFeeDiscountGroupOpMessage,
    UpdateFeeDiscountGroupOpMessage,
    UserDiscountGroupOpMessage,
    TransactionFeeRateOpMessage,
    FeeAmountRangeOpMessage
} from "agau-common/bridge/BridgeTypes.sol";

contract Gas_TokenManager_mintAndLockTokens is TokenManager_InitSetup {
    CommonTokenOpMessage[] internal _commonMsgs;

    function setUp() public virtual override {
        super.setUp();

        _commonMsgs = _generateCommonTokenOpMessages(1, WEIGHT);

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_mintAndLockTokens() public {
        _tokenManager.mintAndLockTokens(_commonMsgs);
    }
}

contract Gas_TokenManager_releaseTokens is TokenManager_TokensMintedAndLocked_SingleMessage {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(address(_bridgeMediator));
    }

    function test_gas_releaseTokens() public {
        _tokenManager.releaseTokens(_commonMsgs);
    }
}

contract Gas_TokenManager_burnTokens is TokenManager_TokensReceivedForRedemption_SingleMessage {
    BurnTokenOpMessage[] internal _burnMsgs;

    function setUp() public virtual override {
        super.setUp();

        _burnMsgs = _generateBurnTokenOpMessages(_commonMsgs);

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_burnTokens() public {
        _tokenManager.burnTokens(_burnMsgs);
    }
}

contract Gas_TokenManager_refundTokens is TokenManager_TokensReceivedForRedemption_SingleMessage {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_refundTokens() public {
        _tokenManager.refundTokens(_commonMsgs);
    }
}

contract Gas_TokenManager_freezeTokens is TokenManager_TokensReleased_SingleMessage {
    TokenManagementOpMessage internal _tokenManagementMsg;

    function setUp() public virtual override {
        super.setUp();

        _tokenManagementMsg = _generateTokenManagementOpMessage(_commonMsgs[0]);

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_freezeTokens() public {
        _tokenManager.freezeTokens(_tokenManagementMsg);
    }
}

contract Gas_TokenManager_unfreezeTokens is TokenManager_TokensFrozen {
    function setUp() public virtual override {
        super.setUp();

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_unfreezeTokens() public {
        _tokenManager.unfreezeTokens(_tokenManagementMsg);
    }
}

contract Gas_TokenManager_seizeTokens is TokenManager_TokensFrozen {
    TokenTransferOpMessage internal _seizeTokensMsg;

    function setUp() public virtual override {
        super.setUp();

        _seizeTokensMsg = _generateTokenTransferOpMessage(_tokenManagementMsg);

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_seizeTokens() public {
        _tokenManager.seizeTokens(_seizeTokensMsg);
    }
}

contract Gas_TokenManager_transferTokens is TokenManager_TokensReceivedForRedemption_SingleMessage {
    TokenTransferOpMessage internal _transferTokensMsg;

    function setUp() public virtual override {
        super.setUp();

        _transferTokensMsg = _generateTokenTransferOpMessage(_commonMsgs[0]);

        vm.prank(address(_bridgeMediator));
    }

    function test_gas_transferTokens() public {
        _tokenManager.transferTokens(_transferTokensMsg);
    }
}

contract Gas_TokenManager_createDiscountGroup is TokenManager_InitSetup {
    CreateFeeDiscountGroupOpMessage internal _generatedMessage;

    function setUp() public virtual override {
        super.setUp();
        _generatedMessage = _generateCreateDiscountGroupMessage();
        vm.prank(address(_bridgeMediator));
    }

    function test_gas_createDiscountGroup() public {
        _tokenManager.createDiscountGroup(_generatedMessage);
    }
}

contract Gas_TokenManager_updateDiscountGroup is TokenManager_FeeDiscountGroupCreated {
    UpdateFeeDiscountGroupOpMessage internal _generatedMessage;

    function setUp() public virtual override {
        super.setUp();

        _generatedMessage = _generateUpdateDiscountGroupMessage();
        vm.prank(address(_bridgeMediator));
    }

    function test_gas_updateDiscountGroup() public {
        _tokenManager.updateDiscountGroup(_generatedMessage);
    }
}

contract Gas_TokenManager_setUserDiscountGroup is TokenManager_FeeDiscountGroupCreated {
    UserDiscountGroupOpMessage internal _generatedMessage;

    function setUp() public virtual override {
        super.setUp();

        _generatedMessage = _generateUserDiscountGroupMessage();
        vm.prank(address(_bridgeMediator));
    }

    function test_gas_setUserDiscountGroup() public {
        _tokenManager.setUserDiscountGroup(_generatedMessage);
    }
}

contract Gas_TokenManager_updateTransactionFeeRate is TokenManager_InitSetup {
    TransactionFeeRateOpMessage internal _generatedMessage;

    function setUp() public virtual override {
        super.setUp();

        _generatedMessage = _generateTransactionFeeRateMessage(TX_FEE_RATE + 1);
        vm.prank(address(_bridgeMediator));
    }

    function test_gas_updateTransactionFeeRate() public {
        _tokenManager.updateTransactionFeeRate(_generatedMessage);
    }
}

contract Gas_TokenManager_updateFeeAmountRange is TokenManager_InitSetup {
    FeeAmountRangeOpMessage internal _generatedMessage;

    function setUp() public virtual override {
        super.setUp();

        _generatedMessage = _generateFeeAmountRangeMessage(1, 2);
        vm.prank(address(_bridgeMediator));
    }

    function test_gas_updateFeeAmountRange() public {
        _tokenManager.updateFeeAmountRange(_generatedMessage);
    }
}

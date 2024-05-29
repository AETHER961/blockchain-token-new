// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {MultiSigValidation} from "../signature/SignatureValidation.sol";
import {AuthorizationGuardAccess} from "./roles/AuthorizationGuardAccess.sol";
import {MetalToken} from "../token/MetalToken.sol";
import {TokenFactory} from "../token/TokenFactory.sol";
import {FeesManager} from "./FeesManager.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {OpsTypes} from "lib/agau-common/admin-ops/OpsTypes.sol";
import {TokenOpTypes} from "lib/agau-types/TokenOpTypes.sol";
import {ITokenManager} from "lib/agau-common/tokens-management/interface/ITokenManager.sol";
import {IFeesWhitelistManager} from "lib/agau-common/admin-ops/interface/IFeesWhitelistManager.sol";
import {
    ITokenizationRecovery
} from "lib/agau-common/tokens-management/tokenization/interface/ITokenizationRecovery.sol";
import {
    IRedemptionCallback
} from "lib/agau-common/tokens-management/redemption/interface/IRedemptionCallback.sol";
import {
    IRedemptionRecovery
} from "lib/agau-common/tokens-management/redemption/interface/IRedemptionRecovery.sol";
import {IOpsRecovery} from "lib/agau-common/admin-ops/interface/IOpsRecovery.sol";

/**
 * @title TokenManager
 * @author
 * @dev Contract that manages tokens contracts.
 *      Its used as the
 *      redemption wallet, meaning the user should send their tokens here to redeem them
 *      for a physical asset.
 */
contract TokenManager is AuthorizationGuardAccess, ITokenManager, IFeesWhitelistManager {
    using SafeERC20 for MetalToken;

    /// @dev `TokenFactory` contract
    TokenFactory private immutable _tokenFactory;
    /// @dev `FeesManager` contract
    FeesManager private immutable _feesManager;

    MultiSigValidation private _multiSigValidation;

    /// @dev mapping for message status
    mapping(bytes32 => bool) private messageExecuted; // added

    /// @param tokenFactory_ The address of `TokenFactory` contract
    /// @param feesManager_ The address of `FeesManager` contract
    constructor(
        address tokenFactory_,
        address feesManager_,
        address[] memory admins_,
        address[] memory authorizedAccounts_,
        address multiSigValidationAddress_,
        address authorizationGuardAddress_
    ) {
        _tokenFactory = TokenFactory(tokenFactory_);
        _feesManager = FeesManager(feesManager_);
        _multiSigValidation = MultiSigValidation(multiSigValidationAddress_);

        __AuthorizationGuardAccess_init(authorizationGuardAddress_);
    }

    // signers => global group
    /// @inheritdoc ITokenManager
    function mintAndLockTokens(
        TokenOpTypes.CommonTokenOpMessageWithSignature[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            if (_multiSigValidation.verifyCommonOpSignature("mintAndLockTokens", messages[i])) {
                MetalToken token = _tokenFactory.tokenForId(messages[i].metalId);
                token.mintAndLock(messages[i].account, toTokenAmount(token, messages[i].weight));
            }
        }
    }

    // signers => global group
    /// @inheritdoc ITokenManager
    function releaseTokens(
        TokenOpTypes.CommonTokenOpMessageWithSignature[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            if (_multiSigValidation.verifyCommonOpSignature("releaseTokens", messages[i])) {
                MetalToken token = _tokenFactory.tokenForId(messages[i].metalId);
                token.release(messages[i].account, toTokenAmount(token, messages[i].weight));
            }
        }
    }

    // signers => global group
    /// @inheritdoc ITokenManager
    function burnTokens(
        TokenOpTypes.BurnTokenOpMessageWithSignature[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            if (_multiSigValidation.verifyBurnOpSignature("burnTokens", messages[i])) {
                MetalToken token = _tokenFactory.tokenForId(messages[i].metalId);
                token.burn(address(this), toTokenAmount(token, messages[i].weight));
            }
        }
    }

    /// @inheritdoc ITokenManager
    function refundTokens(
        TokenOpTypes.CommonTokenOpMessage[] calldata messages
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < messages.length; ++i) {
            MetalToken token = _tokenFactory.tokenForId(messages[0].metalId);
            token.safeTransfer(messages[i].account, toTokenAmount(token, messages[i].weight));
        }
    }

    /// @inheritdoc ITokenManager
    function freezeTokens(
        TokenOpTypes.TokenManagementOpMessage calldata message
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.lock(message.user, message.amount);
    }

    // signer => auditor
    /// @inheritdoc ITokenManager
    function unfreezeTokens(
        TokenOpTypes.TokenManagementOpMessage calldata message
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.unlock(message.user, message.amount);
    }

    /// @inheritdoc ITokenManager
    function seizeTokens(
        TokenOpTypes.TokenTransferOpMessage calldata message
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.seizeLocked(message.from, message.to, message.amount);
    }

    /// @inheritdoc ITokenManager
    function transferTokens(
        TokenOpTypes.TokenTransferOpMessage calldata message
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(message.metalId);
        token.safeTransfer(message.to, message.amount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function createDiscountGroup(
        TokenOpTypes.CreateFeeDiscountGroupOpMessage calldata message
    ) external onlyAdminAccess {
        _feesManager.createDiscountGroup(message.groupType, message.discount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateDiscountGroup(
        TokenOpTypes.UpdateFeeDiscountGroupOpMessage calldata message
    ) external onlyAdminAccess {
        _feesManager.updateDiscountGroup(message.groupType, message.groupId, message.discount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function setUserDiscountGroup(
        TokenOpTypes.UserDiscountGroupOpMessage calldata message
    ) external onlyAdminAccess {
        _feesManager.setGroupForUser(message.groupType, message.groupId, message.user);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateTransactionFeeRate(
        TokenOpTypes.TransactionFeeRateOpMessage calldata message
    ) external onlyAdminAccess {
        _feesManager.setTxFeeRate(message.feeRate);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateFeeAmountRange(
        TokenOpTypes.FeeAmountRangeOpMessage calldata message
    ) external onlyAdminAccess {
        _feesManager.setMinAndMaxTxFee(message.minimumAmount, message.maximumAmount);
    }

    /// @dev Returns the address of the `TokenFactory` contract
    /// @return `TokenFactory` contract address
    function tokenFactory() external view returns (address) {
        return address(_tokenFactory);
    }

    /// @dev Returns the address of the `FeesManager` contract
    /// @return `FeesManager` contract address
    function feesManager() external view returns (address) {
        return address(_feesManager);
    }

    /// @dev Converts the weight to the token amount
    /// @param weight The weight to convert
    /// @return The token amount
    function toTokenAmount(MetalToken token, uint48 weight) public view returns (uint256) {
        return uint256(weight) * 10 ** token.decimals();
    }
}

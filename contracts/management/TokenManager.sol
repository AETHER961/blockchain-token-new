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
        TokenOpTypes.CommonTokenOpWithSignature[] calldata instructions
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < instructions.length; ++i) {
            if (
                _multiSigValidation.verifyCommonOpSignature(
                    "mintAndLockTokens",
                    TokenOpTypes.OpType.MINT_OP,
                    instructions[i]
                )
            ) {
                MetalToken token = _tokenFactory.tokenForId(instructions[i].metalId);
                token.mintAndLock(
                    instructions[i].account,
                    toTokenAmount(token, instructions[i].weight)
                );
            }
        }
    }

    // signers => auditor only
    /// @inheritdoc ITokenManager
    function releaseTokens(
        TokenOpTypes.CommonTokenOpWithSignature[] calldata instructions
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < instructions.length; ++i) {
            if (
                _multiSigValidation.verifyCommonOpSignature(
                    "releaseTokens",
                    TokenOpTypes.OpType.RELEASE_OP,
                    instructions[i]
                )
            ) {
                MetalToken token = _tokenFactory.tokenForId(instructions[i].metalId);
                token.release(
                    instructions[i].account,
                    toTokenAmount(token, instructions[i].weight)
                );
            }
        }
    }

    // no signers
    /// @inheritdoc ITokenManager
    function burnTokens(
        TokenOpTypes.BurnTokenOpWithSignature[] calldata instructions
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < instructions.length; ++i) {
            MetalToken token = _tokenFactory.tokenForId(instructions[i].metalId);
            token.burn(address(this), toTokenAmount(token, instructions[i].weight));
        }
    }

    /// @inheritdoc ITokenManager
    function refundTokens(
        TokenOpTypes.CommonTokenOp[] calldata instructions
    ) external onlyAuthorizedAccess {
        for (uint256 i; i < instructions.length; ++i) {
            MetalToken token = _tokenFactory.tokenForId(instructions[0].metalId);
            token.safeTransfer(
                instructions[i].account,
                toTokenAmount(token, instructions[i].weight)
            );
        }
    }

    /// @inheritdoc ITokenManager
    function freezeTokens(
        TokenOpTypes.TokenManagementOp calldata instruction
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(instruction.metalId);
        token.lock(instruction.user, instruction.amount);
    }

    // signer => auditor
    /// @inheritdoc ITokenManager
    function unfreezeTokens(
        TokenOpTypes.TokenManagementOp calldata instruction
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(instruction.metalId);
        token.unlock(instruction.user, instruction.amount);
    }

    /// @inheritdoc ITokenManager
    function seizeTokens(
        TokenOpTypes.TokenTransferOp calldata instruction
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(instruction.metalId);
        token.seizeLocked(instruction.from, instruction.to, instruction.amount);
    }

    /// @inheritdoc ITokenManager
    function transferTokens(
        TokenOpTypes.TokenTransferOp calldata instruction
    ) external onlyAdminAccess {
        MetalToken token = _tokenFactory.tokenForId(instruction.metalId);
        token.safeTransfer(instruction.to, instruction.amount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function createDiscountGroup(
        TokenOpTypes.CreateFeeDiscountGroupOp calldata instruction
    ) external onlyAdminAccess {
        _feesManager.createDiscountGroup(instruction.groupType, instruction.discount);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateDiscountGroup(
        TokenOpTypes.UpdateFeeDiscountGroupOp calldata instruction
    ) external onlyAdminAccess {
        _feesManager.updateDiscountGroup(
            instruction.groupType,
            instruction.groupId,
            instruction.discount
        );
    }

    /// @inheritdoc IFeesWhitelistManager
    function setUserDiscountGroup(
        TokenOpTypes.UserDiscountGroupOp calldata instruction
    ) external onlyAdminAccess {
        _feesManager.setGroupForUser(instruction.groupType, instruction.groupId, instruction.user);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateTransactionFeeRate(
        TokenOpTypes.TransactionFeeRateOp calldata instruction
    ) external onlyAdminAccess {
        _feesManager.setTxFeeRate(instruction.feeRate);
    }

    /// @inheritdoc IFeesWhitelistManager
    function updateFeeAmountRange(
        TokenOpTypes.FeeAmountRangeOp calldata instruction
    ) external onlyAdminAccess {
        _feesManager.setMinAndMaxTxFee(instruction.minimumAmount, instruction.maximumAmount);
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

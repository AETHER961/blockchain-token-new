// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {MetalToken} from "contracts/token/MetalToken.sol";

/**
 * @title TokenFactory
 * @author
 * @dev Factory contract for creating `MetalToken` contracts
 */
contract TokenFactory is Ownable2Step {
    /// @dev Token initialization parameters
    struct TokenInitParam {
        // Token identifier
        uint256 tokenId;
        // Token owner
        address owner;
        // `FeesManager` contract address
        address feesManager;
        // Name of the token
        string name;
        // Symbol of the token
        string symbol;
        address authorizationGuard;
    }

    /// @dev Beacon for token proxy contracts
    address private immutable _tokenBeacon;

    /// @dev Mapping of token identifier to token address
    mapping(uint256 => MetalToken) private _tokens;

    /// @dev Emitted when token is created
    /// @param tokenId Token id
    /// @param token Token address
    event TokenCreated(uint256 tokenId, address token);

    /// @dev Token with given identifier does not exist
    /// @param id Identifier of the token
    error TokenNotExist(uint256 id);

    /// @dev Token with given identifier already exists
    /// @param id Identifier of the token
    error TokenAlreadyExist(uint256 id);

    /// @param owner_ Owner address
    /// @param tokenBeacon_ Beacon address for token proxy contracts
    /// @param initTokens Array of token initialization parameters for creating tokens on deployment
    constructor(
        address owner_,
        address tokenBeacon_,
        TokenInitParam[] memory initTokens
    ) Ownable(owner_) {
        _tokenBeacon = tokenBeacon_;

        for (uint256 i; i < initTokens.length; ++i) {
            _createToken(initTokens[i]);
        }
    }

    /// @dev Creates a new `MetalToken` proxy contract
    ///      Callable only by authorized accounts
    ///      Emits a {TokenCreated} event
    /// @param initParam Token initialization parameters
    function createToken(TokenInitParam calldata initParam) external onlyOwner {
        _createToken(initParam);
    }

    /// @dev Returns token address for an identifier
    /// @param id Identifier of the token
    /// @return token Token address
    function tokenForId(uint256 id) external view returns (MetalToken token) {
        token = _tokens[id];
        if (address(token) == address(0)) revert TokenNotExist(id);
    }

    /// @dev Returns beacon address for token proxy contracts
    /// @return tokenBeacon Beacon address
    function tokenBeacon() external view returns (address) {
        return _tokenBeacon;
    }

    /// @dev Creates a new `MetalToken` proxy contract
    ///      Emits a {TokenCreated} event
    /// @param initParams Token initialization parameters
    function _createToken(TokenInitParam memory initParams) private {
        if (address(_tokens[initParams.tokenId]) != address(0)) {
            revert TokenAlreadyExist(initParams.tokenId);
        }
        // Encode data for initializer call
        bytes memory initData = abi.encodeCall(
            MetalToken.initialize,
            (
                initParams.owner,
                initParams.feesManager,
                initParams.name,
                initParams.symbol,
                initParams.authorizationGuard
            )
        );

        address tokenContract = address(new BeaconProxy(_tokenBeacon, initData));
        _tokens[initParams.tokenId] = MetalToken(tokenContract);

        emit TokenCreated(initParams.tokenId, tokenContract);
    }
}

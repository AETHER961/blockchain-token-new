// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {Constants} from "tests/sol/Constants.t.sol";

import {FeesManager} from "contracts/management/FeesManager.sol";
import {MetalToken} from "contracts/token/MetalToken.sol";
import {TokenFactory} from "contracts/token/TokenFactory.sol";
import {TokenManager} from "contracts/management/TokenManager.sol";

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import {BridgeMediatorMock} from "tests/sol/mock/BridgeMediatorMock.t.sol";

struct TestsConfig {
    uint256 numOfMessages;
}

abstract contract BaseTest is Test, Constants, BridgeMediatorMock {
    TestsConfig internal _testsConfig;
    TokenFactory internal _tokenFactory;
    FeesManager internal _feesManager;
    TokenManager internal _tokenManager;
    UpgradeableBeacon internal _metalTokenBeacon;
    MetalToken internal _token;

    function setUp() public virtual {
        _testsConfig = _readTestsConfig();

        vm.startPrank(OWNER);
        // Every call will be mocked
        vm.mockCall(_bridgeMediator, abi.encode(), abi.encode(0));

        address metalToken = address(new MetalToken());
        _metalTokenBeacon = new UpgradeableBeacon(metalToken, OWNER);

        address expectedTokenManagerAddress = vm.computeCreateAddress(
            OWNER,
            // +2 as current nonce is for `FeesManager` deployment and +1 for `TokenFactory` deployment
            vm.getNonce(OWNER) + 2
        );
        address[] memory zeroFeeAccounts = new address[](2);
        zeroFeeAccounts[0] = ZERO_FEE_ACCOUNT;
        zeroFeeAccounts[1] = expectedTokenManagerAddress;

        _feesManager = new FeesManager();
        _feesManager.initialize(FEE_WALLET, TX_FEE_RATE, MIN_TX_FEE, MAX_TX_FEE, zeroFeeAccounts);

        _tokenFactory = new TokenFactory(
            OWNER,
            address(_metalTokenBeacon),
            _createDummyTokenInitParamAsSingleton(address(_feesManager))
        );

        _tokenManager = new TokenManager(
            _bridgeMediator,
            address(_tokenFactory),
            address(_feesManager)
        );

        if (expectedTokenManagerAddress != address(_tokenManager))
            revert("TokenManager address is not as expected");

        _feesManager.setAuthorized(address(_tokenManager), true);
        _token = MetalToken(_tokenFactory.tokenForId(TOKEN_ID));
        _token.setAuthorized(address(_tokenManager), true);
        vm.stopPrank();
    }

    function _readTestsConfig() internal view returns (TestsConfig memory) {
        bytes memory testsConfig = _readJson("scripts/config/test/config.json");
        return abi.decode(testsConfig, (TestsConfig));
    }

    function _readJson(string memory _file) private view returns (bytes memory _fileData) {
        // Read file. If file doesn't exist, return empty bytes.
        try vm.readFile(_file) returns (string memory _fileStr) {
            _fileData = bytes(_fileStr).length > 0 ? vm.parseJson(_fileStr) : new bytes(0);
        } catch (bytes memory) {
            _fileData = new bytes(0);
        }
    }

    function _createDummyTokenInitParamAsSingleton(
        address feesManager
    ) private view returns (TokenFactory.TokenInitParam[] memory tokenInitParams) {
        tokenInitParams = new TokenFactory.TokenInitParam[](1);
        tokenInitParams[0] = _createDummyTokenInitParam(feesManager);
    }

    function _createDummyTokenInitParam(
        address feesManager
    ) private view returns (TokenFactory.TokenInitParam memory) {
        return
            TokenFactory.TokenInitParam({
                tokenId: TOKEN_ID,
                name: NAME,
                symbol: SYMBOL,
                owner: OWNER,
                feesManager: feesManager
            });
    }

    // This is needed so that "forge coverage" will ignore this contract
    function testSkip() public virtual override {}
}

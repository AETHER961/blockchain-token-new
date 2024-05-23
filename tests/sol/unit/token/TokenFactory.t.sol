// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";

import {MetalToken} from "contracts/token/MetalToken.sol";
import {TokenFactory} from "contracts/token/TokenFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract TokenFactoryTest is Test {
    TokenFactory public tokenFactory;
    address owner = makeAddr("owner");
    MetalToken token = new MetalToken();
    UpgradeableBeacon tokenBeacon = new UpgradeableBeacon(address(token), owner);

    // Copied from TokenFactory.sol
    event TokenCreated(uint256 tokenId, address token);

    function setUp() public {
        tokenFactory = new TokenFactory(
            owner,
            address(tokenBeacon),
            new TokenFactory.TokenInitParam[](0)
        );
    }

    function _createDummyTokenInitParam() private returns (TokenFactory.TokenInitParam memory) {
        return
            TokenFactory.TokenInitParam({
                tokenId: 1,
                name: "Gold",
                symbol: "GLD",
                owner: makeAddr("owner"),
                feesManager: makeAddr("feesManager")
            });
    }

    function _createDummyTokenInitParamsAsSingleton()
        private
        returns (TokenFactory.TokenInitParam[] memory tokenInitParams)
    {
        tokenInitParams = new TokenFactory.TokenInitParam[](1);
        tokenInitParams[0] = _createDummyTokenInitParam();
    }

    //----------------
    // constructor test
    //----------------

    function test_constructor_properSetup() public {
        TokenFactory.TokenInitParam[]
            memory tokenInitParams = _createDummyTokenInitParamsAsSingleton();
        tokenFactory = new TokenFactory(owner, address(tokenBeacon), tokenInitParams);

        assertEq(tokenFactory.owner(), owner);
        assertEq(tokenFactory.tokenBeacon(), address(tokenBeacon));
        assertNotEq(address(tokenFactory.tokenForId(tokenInitParams[0].tokenId)), address(0));
    }

    //----------------
    // `createToken` test
    //----------------

    function test_createToken_revertsWhen_callerNotAuthorized(address nonOwner) public {
        vm.assume(nonOwner != owner);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner)
        );

        vm.prank(nonOwner);
        tokenFactory.createToken(_createDummyTokenInitParam());
    }

    function test_createToken_revertsWhen_tokenIdAlreadyExists() public {
        TokenFactory.TokenInitParam memory tokenInitParam = _createDummyTokenInitParam();

        vm.startPrank(owner);
        tokenFactory.createToken(tokenInitParam);

        vm.expectRevert(
            abi.encodeWithSelector(TokenFactory.TokenAlreadyExist.selector, tokenInitParam.tokenId)
        );

        tokenFactory.createToken(tokenInitParam);
    }

    function test_createToken_properlySetup() public {
        TokenFactory.TokenInitParam memory tokenInitParam = _createDummyTokenInitParam();

        address expectedTokenProxyAddr = vm.computeCreateAddress(address(tokenFactory), 1);

        vm.expectEmit(address(tokenFactory));
        emit TokenCreated(tokenInitParam.tokenId, expectedTokenProxyAddr);

        vm.prank(owner);
        tokenFactory.createToken(tokenInitParam);

        assertNotEq(address(tokenFactory.tokenForId(tokenInitParam.tokenId)), address(0));
    }

    //----------------
    // `tokenForId` test
    //----------------

    function test_tokenForId_returnsTokenForId() public {
        TokenFactory.TokenInitParam memory tokenInitParam = _createDummyTokenInitParam();

        vm.expectRevert(
            abi.encodeWithSelector(TokenFactory.TokenNotExist.selector, tokenInitParam.tokenId)
        );

        assertEq(address(tokenFactory.tokenForId(tokenInitParam.tokenId)), address(0));

        vm.startPrank(owner);
        tokenFactory.createToken(tokenInitParam);

        assertNotEq(address(tokenFactory.tokenForId(tokenInitParam.tokenId)), address(0));
    }
}

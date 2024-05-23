import { expect } from "chai";
import { Contract } from "ethers";
import { getContract } from "../../../scripts/helpers/utils";
import { ethers, upgrades } from "hardhat";

import {
    getAMBContract,
    getForeignMediator,
    getFeeRate,
    getFeeWallet,
} from "../../../scripts/helpers/env";

import * as fullDeployment from "../../../scripts/src/full-deploy";
import { generateIncomingRoutingConfig } from "../../../scripts/config/bridge/config";
import { getTokensMetadata } from "../../../scripts/config/token/config";

describe(`Full deployment tests`, () => {
    const feesWallet = getFeeWallet();
    let deployerAddress: string;

    let bridgeMediator: Contract;
    let metalTokenBeacon: Contract;
    let feesManager: Contract;
    let tokenFactory: Contract;
    let tokenManager: Contract;

    before(async () => {
        await fullDeployment.fullDeploy();
        deployerAddress = fullDeployment.deployerAddr;

        bridgeMediator = await getContract(`BridgeMediator`);
        metalTokenBeacon = await getContract(`MetalToken`);
        feesManager = await getContract(`FeesManager`);
        tokenFactory = await getContract(`TokenFactory`);
        tokenManager = await getContract(`TokenManager`);
    });

    describe(`BridgeMediator deployment`, () => {
        it(`Should be properly set up`, async () => {
            expect(await bridgeMediator.owner()).to.equal(deployerAddress);
            expect(await bridgeMediator.AMBContract()).to.be.equal(getAMBContract());
            expect(await bridgeMediator.mediatorOnOtherSide()).to.be.equal(getForeignMediator());
            expect(await bridgeMediator.authorized(tokenManager.target)).to.be.true;

            const routingConfigs = await generateIncomingRoutingConfig({
                tokenManager: tokenManager.target,
            });

            for (const routingConfig of routingConfigs) {
                expect(await bridgeMediator.routingTarget(routingConfig.selector)).to.be.equal(
                    routingConfig.target,
                );
            }
        });
    });

    describe(`MetalTokenBeacon deployment`, () => {
        it(`Should be properly set up`, async () => {
            expect(await metalTokenBeacon.owner()).to.equal(deployerAddress);
            expect(
                await upgrades.beacon.getImplementationAddress(metalTokenBeacon.target.toString()),
            ).to.not.be.equal(ethers.ZeroAddress);
        });
    });

    describe(`FeesManager deployment`, () => {
        it(`Should be properly set up`, async () => {
            expect(await feesManager.owner()).to.equal(deployerAddress);
            expect(await feesManager.feesWallet()).to.equal(feesWallet);
            expect(await feesManager.txFeeRate()).to.equal(getFeeRate());
            expect(await feesManager.minTxFee()).to.equal(0);
            expect(await feesManager.maxTxFee()).to.equal(ethers.MaxUint256);
            expect(await feesManager.authorized(tokenManager.target)).to.be.true;
            // 1 group type is TX_FEE, 1 is an identifier of the zero tx fee group
            expect(await feesManager.discountGroupIdForUser(1, feesWallet)).to.be.eq(1);
            expect(await feesManager.discountGroupIdForUser(1, tokenManager.target)).to.be.eq(1);
        });
    });

    describe(`TokenFactory and Tokens deployment`, () => {
        it(`Should be properly set up`, async () => {
            expect(await tokenFactory.owner()).to.equal(deployerAddress);
            expect(await tokenFactory.tokenBeacon()).to.equal(metalTokenBeacon.target);

            const tokensMetadata = getTokensMetadata(deployerAddress, feesManager.target);
            for (const tokenMetadata of tokensMetadata) {
                const tokenAddress = await tokenFactory.tokenForId(tokenMetadata.tokenId);
                const token = await ethers.getContractAt(`MetalToken`, tokenAddress);
                expect(await token.owner()).to.equal(tokenMetadata.owner);
                expect(await token.name()).to.equal(tokenMetadata.name);
                expect(await token.symbol()).to.equal(tokenMetadata.symbol);
            }
        });
    });

    describe(`TokenManager deployment`, () => {
        it(`Should be properly set up`, async () => {
            expect(await tokenManager.bridgeMediator()).to.equal(bridgeMediator.target);
            expect(await tokenManager.tokenFactory()).to.equal(tokenFactory.target);
            expect(await tokenManager.feesManager()).to.equal(feesManager.target);
        });
    });
});

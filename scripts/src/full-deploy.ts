import { ethers, tenderly, upgrades } from "hardhat";
import { chainIds } from "../../hardhat.config";

import { trackDeployment, trackTransaction, updateDeploymentsJson } from "../helpers/utils";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { TokenIdentifier, getTokensMetadata } from "../config/token/config";
import { getAMBContract, getForeignMediator, getFeeRate, getFeeWallet } from "../helpers/env";

import * as deployment from "../helpers/deploy";
import { generateIncomingRoutingConfig } from "../config/bridge/config";

const isTestnetDeployment = async (): Promise<boolean> => {
    return (await ethers.provider.getNetwork()).chainId === chainIds.tenderly;
};

export let deployerAddr: string;

export const fullDeploy = async (): Promise<void> => {
    const [deployer] = await ethers.getSigners();
    deployerAddr = deployer.address;
    const testnetDeployment = await isTestnetDeployment();

    if (testnetDeployment) {
        // Top up the deployer account with ETH on Tenderly testnet
        await ethers.provider.send(`tenderly_setBalance`, [
            [deployerAddr],
            ethers.toQuantity(ethers.parseUnits(`1000`, `ether`)),
        ]);
    }

    const balance = (await ethers.provider.getBalance(deployerAddr)).toString();
    // console.log(`Deploying contracts with the account ${deployerAddr} and balance: ${balance}`);

    // Deploy `BridgeMediator` contract
    const bridgeMediator = await trackDeployment(
        () =>
            deployment.deployBridgeMediator(deployer, {
                AMBContract: getAMBContract(),
                foreignMediator: getForeignMediator(),
                owner: deployerAddr,
            }),
        `BridgeMediator`,
    );

    // Deploy `MetalToken` beacon
    const metalTokenBeacon = await trackDeployment(
        () => deployment.deployMetalTokenBeacon(deployer),
        `MetalToken`,
    );

    // Deploy `FeesManager` proxy
    const expectedTokenManagerAddress = ethers.getCreateAddress({
        from: deployerAddr,
        // +4 as current nonce +2 (sum +3) is for `FeesManager` deployment and +1 is for `TokenFactory` deployment
        nonce: (await deployer.getNonce()) + 4,
    });
    const feeWallet = getFeeWallet();
    const feesManagerProxy = await trackDeployment(
        () =>
            deployment.deployFeesManager(deployer, {
                feeWallet: feeWallet,
                txFeeRate: getFeeRate(),
                minTxFee: 0n,
                maxTxFee: ethers.MaxUint256,
                zeroFeeAccounts: [feeWallet, expectedTokenManagerAddress],
            }),
        `FeesManager`,
    );

    // Deploy `TokenFactory` contract
    const tokensMetadata = getTokensMetadata(deployerAddr, feesManagerProxy.target);
    const tokenFactory = await trackDeployment(
        () =>
            deployment.deployTokenFactory(deployer, {
                owner: deployerAddr,
                tokenBeacon: metalTokenBeacon.target,
                initTokens: tokensMetadata,
            }),
        `TokenFactory`,
    );

    // Deploy `TokenManager` contract
    const tokenManager = await trackDeployment(
        () =>
            deployment.deployTokenManager(deployer, {
                mediator: bridgeMediator.target,
                tokenFactory: tokenFactory.target,
                feesManager: feesManagerProxy.target,
            }),
        `TokenManager`,
    );

    // In case of testnet deployment, verify the proxy and beacon contracts on Tenderly
    if (testnetDeployment) {
        await tenderly.verify({
            name: `FeesManager`,
            address: await getImplementationAddress(
                ethers.provider,
                feesManagerProxy.target.toString(),
            ),
        });

        await tenderly.verify({
            name: `MetalToken`,
            address: await upgrades.beacon.getImplementationAddress(
                metalTokenBeacon.target.toString(),
            ),
        });
    }

    // Must be retrieved like this as these are beacon proxies created during the deployment of `TokenFactory`
    const goldToken = await ethers.getContractAt(
        `MetalToken`,
        await tokenFactory.tokenForId(TokenIdentifier.Gold),
    );
    const silverToken = await ethers.getContractAt(
        `MetalToken`,
        await tokenFactory.tokenForId(TokenIdentifier.Silver),
    );

    const routingConfig = await generateIncomingRoutingConfig({
        tokenManager: tokenManager.target,
    });

    const chainId = (await ethers.provider.getNetwork()).chainId;
    // Write the deployment results for metal token beacon proxies as they are already deployed via `TokenFactory`
    updateDeploymentsJson(`GoldToken`, goldToken.target, chainId);
    updateDeploymentsJson(`SilverToken`, silverToken.target, chainId);

    await trackTransaction(
        bridgeMediator.setIncomingMessagesConfigs(routingConfig),
        `Set the incoming messages routing configuration on BridgeMediator`,
    );

    await trackTransaction(
        bridgeMediator.setAuthorized(tokenManager.target, true),
        `Set the TokenManager as authorized on BridgeMediator`,
    );

    await trackTransaction(
        goldToken.setAuthorized(tokenManager.target, true),
        `Set the TokenManager as authorized on Gold Token`,
    );

    await trackTransaction(
        silverToken.setAuthorized(tokenManager.target, true),
        `Set the TokenManager as authorized on Silver Token`,
    );

    await trackTransaction(
        feesManagerProxy.setAuthorized(tokenManager.target, true),
        `Set the TokenManager as authorized on FeesManager`,
    );
};

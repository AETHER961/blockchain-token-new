// // scripts/deploy.js



import { ethers, tenderly, upgrades } from "hardhat";
import { chainIds } from "../../hardhat.config";

import { trackDeployment, trackTransaction, updateDeploymentsJson } from "../helpers/utils";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { TokenIdentifier, getTokensMetadata } from "../config/token/config";
import { getAMBContract, getForeignMediator, getFeeRate, getFeeWallet } from "../helpers/env";

import * as deployment from "../helpers/deploy";
import { generateIncomingRoutingConfig } from "../config/bridge/config";

const feesWallet = getFeeWallet();

const adminAddresses = [
    feesWallet,
];

const authorizedAdmins = [
    feesWallet,
    "0xafCa393205656Ca3B60B8BA31EFA225d5B72A726",
    "0x3528C7b21cd34fe32CdDA2806CB2E18A4659e8c1"
];

const signers = [
    feesWallet,
    "0xafCa393205656Ca3B60B8BA31EFA225d5B72A726",
    "0x3528C7b21cd34fe32CdDA2806CB2E18A4659e8c1"
]
const roles = [
    "Director",
    "Token Manager",
    "Token Manager 2"
];


const tokenFactoryOwner = feesWallet;


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
    console.log(`Deploying contracts with the account ${deployerAddr} and balance: ${balance}`);
    // console.log(`Admins:`, adminAddresses);
    // console.log(`authriied:`, authorizedAdmins);

    // Deploy `authorizationGuard`
    const authorizationGuard = await trackDeployment(
        () => deployment.deployAuthorizationGuard(deployer, {
            adminAddresses,
            authorizedAccounts: authorizedAdmins
        }),
        `AuthorizationGuard`,
    );

    console.log(`AuthorizationGuard deployed at ${authorizationGuard.target}`);

    // Deploy Multi Signature Validation contract
    const multiSigValidation = await trackDeployment(
        () => deployment.deployMultiSigValidation(deployer, {
            requiredSignatures: BigInt(signers.length),
            authorizationGuard: authorizationGuard.target,
            signers,
            roles
        }),
        `MultiSigValidation`
    )

    console.log(`MultiSigValidation deployed at ${multiSigValidation.target}`);


    // Deploy `MetalToken` beacon
    const metalTokenBeacon = await trackDeployment(
        () => deployment.deployMetalTokenBeacon(deployer),
        `MetalToken`,
    );

    console.log(`MetalToken Beacon proxy deployed at ${metalTokenBeacon.target}`);


    // Deploy `FeesManager` proxy
    const expectedTokenManagerAddress = ethers.getCreateAddress({
        from: deployerAddr,
        // +3 as current nonce +2 (sum +3) is for `FeesManager` deployment and +1 is for `TokenFactory` deployment
        nonce: (await deployer.getNonce()) + 3,
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
                authorizationGuard: authorizationGuard.target
            }),
        `FeesManager`,
    );

    console.log(`FeesManager deployed at ${feesManagerProxy.target}`);


    // Deploy `TokenFactory` contract
    const tokensMetadata = getTokensMetadata(deployerAddr, feesManagerProxy.target, authorizationGuard.target);
    const tokenFactory = await trackDeployment(
        () =>
            deployment.deployTokenFactory(deployer, {
                owner: deployerAddr,
                tokenBeacon: metalTokenBeacon.target,
                initTokens: tokensMetadata,
            }),
        `TokenFactory`,
    );

    console.log(`TokenFactory deployed at ${tokenFactory.target}`);

    // Deploy `TokenManager` contract
    const tokenManager = await trackDeployment(
        () =>
            deployment.deployTokenManager(deployer, {
                tokenFactory: tokenFactory.target,
                feesManager: feesManagerProxy.target,
                adminAddresses: adminAddresses,
                authorizedAddresses: authorizedAdmins,
                multiSigValidationAddress: multiSigValidation.target,
                authorizedGuardAddress: authorizationGuard.target
            }),
        `TokenManager`,
    );

    console.log(`TokenManager deployed at ${tokenManager.target}`);


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
    console.log(`Gold MetalToken deployed at ${goldToken.target}`);


    const silverToken = await ethers.getContractAt(
        `MetalToken`,
        await tokenFactory.tokenForId(TokenIdentifier.Silver),
    );

    console.log(`Gold MetalToken deployed at ${silverToken.target}`);

    const routingConfig = await generateIncomingRoutingConfig({
        tokenManager: tokenManager.target,
    });

    const chainId = (await ethers.provider.getNetwork()).chainId;
    // Write the deployment results for metal token beacon proxies as they are already deployed via `TokenFactory`
    updateDeploymentsJson(`GoldToken`, goldToken.target, chainId);
    updateDeploymentsJson(`SilverToken`, silverToken.target, chainId);

};

fullDeploy().catch((error) => {
    console.log(`full deploy running...`)
    console.error(error);
    process.exitCode = 1;
});


// import { ethers } from "hardhat";
// import { getFeeWallet } from "../helpers/env";

// const adminAddresses = [
//     "0x5798C0C8Cc396Da77Aaa68c0722B70926f98946C",
//     "0x7eDD7D2190BE0ff63E75ee8B02ab458dA12335EC",
// ];

// const authorizedAdmins = [
//     "0x5798C0C8Cc396Da77Aaa68c0722B70926f98946C",
//     "0xafCa393205656Ca3B60B8BA31EFA225d5B72A726",
//     "0x3528C7b21cd34fe32CdDA2806CB2E18A4659e8c1"
// ];

// const signers = [
//     "0x5798C0C8Cc396Da77Aaa68c0722B70926f98946C",
//     "0xafCa393205656Ca3B60B8BA31EFA225d5B72A726",
//     "0x3528C7b21cd34fe32CdDA2806CB2E18A4659e8c1"
// ]
// const roles = [
//     "Director",
//     "Token Manager",
//     "Token Manager 2"
// ];

// const feesWallet = getFeeWallet();

// const tokenFactoryOwner = "0x5798C0C8Cc396Da77Aaa68c0722B70926f98946C";

// async function main() {
// // Deploy AuthorizationGuard
// const AuthorizationGuard = await ethers.getContractFactory("AuthorizationGuard");
// const authorizationGuard = await AuthorizationGuard.deploy(
//     adminAddresses,
//     authorizedAdmins
// );
// await authorizationGuard.deployed();
// console.log("AuthorizationGuard deployed to:", authorizationGuard.address);

// // Deploy MultiSigValidation
// const MultiSigValidation = await ethers.getContractFactory("MultiSigValidation");
// const multiSigValidation = await MultiSigValidation.deploy(
//     signers.length, // required signatures
//     authorizationGuard.address,
//     signers,
//     roles
// );
// await multiSigValidation.deployed();
// console.log("MultiSigValidation deployed to:", multiSigValidation.address);

// const setupRoles = await multiSigValidation.getRoles();
// console.log(`Setup roles in contract:`, setupRoles);


// // Deploy FeesManager
// const FeesManager = await ethers.getContractFactory("FeesManager");
// const feesManager = await FeesManager.deploy();
// await feesManager.deployed();
// console.log("FeesManager deployed to:", feesManager.address);

// // Initialize FeesManager
// await feesManager.initialize(
//     feesWallet,
//     100, // txFeeRate
//     10, // minTxFee
//     1000, // maxTxFee
//     adminAddresses // zero fee wallets
// );
// console.log("FeesManager initialized");


// // Deploy MetalToken Implementation contract
// const MetalToken = await ethers.getContractFactory("MetalToken");
// const metalToken = await MetalToken.deploy();
// await metalToken.deployed();
// console.log("MetalToken deployed to:", metalToken.address);

// // Deploy TokenFactory
// const TokenFactory = await ethers.getContractFactory("TokenFactory");
// const tokenFactory = await TokenFactory.deploy(
//     tokenFactoryOwner,
//     "tokenBeacon_address", // replace with actual token beacon address
//     [] // replace with actual token initialization parameters if any
// );
// await tokenFactory.deployed();
// console.log("TokenFactory deployed to:", tokenFactory.address);

// // Deploy TokenManager
// const TokenManager = await ethers.getContractFactory("TokenManager");
// const tokenManager = await TokenManager.deploy(
//     tokenFactory.address,
//     feesManager.address,
//     ["admin1_address", "admin2_address"], // replace with actual admin addresses
//     ["authorizedAccount1_address", "authorizedAccount2_address"], // replace with actual authorized account addresses
//     multiSigValidation.address,
//     authorizationGuard.address
// );
// await tokenManager.deployed();
// console.log("TokenManager deployed to:", tokenManager.address);
// }

// main().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

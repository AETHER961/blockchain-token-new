import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

import * as deployment from "../../deployments.json";
import * as verifyMultiSig from "../../scripts/verify/verify-multisigvalidation";
import * as verifyAuthorizationGuard from "../../scripts/verify/verify-authorizationguard";
import * as verifyMetalToken from "../../scripts/verify/verify-metaltoken";
import * as verifyFeesManager from "../../scripts/verify/verify-feesmanager";
import * as verifyTokenFactory from "../../scripts/verify/verify-tokenfactory";
import * as verifyTokenManager from "../../scripts/verify/verify-tokenmanager";

type NetworkNames = 'bsc' | 'sepolia' | 'hardhat';

const verificationParams: { [key: string]: any } = {
    'AuthorizationGuard': { func: verifyAuthorizationGuard.main, isProxy: false },
    'MultiSigValidation': { func: verifyMultiSig.main, isProxy: false },
    'MetalToken': { func: verifyMetalToken.main, isProxy: true },
    'FeesManager': { func: verifyFeesManager.main, isProxy: true },
    'TokenFactory': { func: verifyTokenFactory.main, isProxy: true },
    'TokenManager': { func: verifyTokenManager.main, isProxy: true },
    'GoldToken': { func: verifyMetalToken.main, isProxy: true },
    'SilverToken': { func: verifyMetalToken.main, isProxy: true },
}

export const verifyAllContracts = async () => {
    try {

        const networkName: NetworkNames = 'sepolia';
        const contractDeployment = deployment.deployments.find((deploymentConf) => deploymentConf.network === networkName);

        if (!contractDeployment) throw new Error(`Failed to fetch contract deployment addresses`);
        console.log(`Retrieved contracts for ${networkName}`, contractDeployment);
        for (let contract of contractDeployment?.contracts) {
            console.log(`Attempting to verify ${contract.name}`);

            let verify;
            // if (contract.name.includes('Gold') || contract.name.includes('Silver')) {
            //     console.log(`includes gold or silver_))))0`)
            //     verify = verificationParams['MetalToken'].func;
            // }
            // else {
            //     if (!verificationParams[contract.name]) {
            //         throw new Error(`Failed to fetch verification parameters for ${contract.name}`)
            //     }
            //     verify = verificationParams[contract.name].func;
            // }

            verify = verificationParams[contract.name].func;

            switch (contract.name) {
                case 'AuthorizationGuard':
                    const tokenManager = contractDeployment.contracts.find((contractObj) => contractObj.name === 'TokenManager');
                    console.log(`[Verify AuthorizationGuard]: Retrieved token manager:`, tokenManager)
                    await verify(contract.address, tokenManager?.address);
                    break;
                case 'MultiSigValidation':
                    const authorizationGuard = contractDeployment.contracts.find((contractObj) => contractObj.name === 'AuthorizationGuard')
                    await verify(contract.address, authorizationGuard?.address);
                    break;

                case 'TokenManager':
                    const tokenFactory = contractDeployment.contracts.find((contractObj) => contractObj.name === 'TokenFactory');
                    const feesManager = contractDeployment.contracts.find((contractObj) => contractObj.name === 'FeesManager');
                    const multisigValidation = contractDeployment.contracts.find((contractObj) => contractObj.name === 'MultiSigValidation');
                    const authorizationGuardAddress = contractDeployment.contracts.find((contractObj) => contractObj.name === 'AuthorizationGuard');

                    console.log(`)Token factory address:`, tokenFactory)
                    console.log(`)Fees manager address:`, feesManager)
                    await verify(contract.address, tokenFactory?.address, feesManager?.address, multisigValidation?.address, authorizationGuardAddress?.address);
                    break;

                case 'TokenFactory':
                    const feesManagerContr = contractDeployment.contracts.find((contractObj) => contractObj.name === 'FeesManager');
                    const authorizationGuardContr = contractDeployment.contracts.find((contractObj) => contractObj.name === 'AuthorizationGuard');
                    const metalBeaconToken = contractDeployment.contracts.find((contractObj) => contractObj.name === 'MetalToken');
                    console.log(`Verifying tokenfactory)()()()()()()`, {
                        feesManagerContr, authorizationGuardContr, metalBeaconToken
                    })

                    await verify(contract.address, feesManagerContr?.address, authorizationGuardContr?.address, metalBeaconToken?.address);
                    break;

                case 'MetalToken':
                    // const feesManagerAddress = contractDeployment.contracts.find((contractObj) => contractObj.name === 'FeesManager');
                    // await verify(contract.address, feesManager?.address, authorizationGuardAddress?.address, feesManagerAddress?.address);

                    break;
                case 'GoldToken':
                    verify = verificationParams['MetalToken'].func;
                    const feesManagerAddress = contractDeployment.contracts.find((contractObj) => contractObj.name === 'FeesManager');
                    const metalToken = contractDeployment.contracts.find((contractObj) => contractObj.name === 'MetalToken');
                    const authorizationGuardContractAddress = contractDeployment.contracts.find((contractObj) => contractObj.name === 'AuthorizationGuard');
                    const tokenFactoryContr = contractDeployment.contracts.find((contractObj) => contractObj.name === 'TokenFactory');

                    await verify(contract.address, feesManagerAddress?.address, authorizationGuardContractAddress?.address, tokenFactoryContr?.address, 0);
                    break;
                case 'SilverToken':
                    verify = verificationParams['MetalToken'].func;

                    const feesManagerContract = contractDeployment.contracts.find((contractObj) => contractObj.name === 'FeesManager');
                    const metalTokenAddress = contractDeployment.contracts.find((contractObj) => contractObj.name === 'MetalToken');
                    const authorizationGuardContract = contractDeployment.contracts.find((contractObj) => contractObj.name === 'AuthorizationGuard');
                    const tokenFactoryContrAddress = contractDeployment.contracts.find((contractObj) => contractObj.name === 'TokenFactory');

                    await verify(contract.address, feesManagerContract?.address, authorizationGuardContract?.address, tokenFactoryContrAddress?.address, 1);
                    break;
                default:
                    console.log(`************** Starting verif for ${contract.name}`)
                    await verify(contract.address);

                    break;
            }

            console.log(`Verified! ${contract.name} ${contract.address}`);

        }

    } catch (error) {
        console.error(`Verify-All: error`, error);
    }
}


verifyAllContracts()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

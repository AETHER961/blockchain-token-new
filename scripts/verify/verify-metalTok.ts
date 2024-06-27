import { ethers, upgrades, run } from "hardhat";
import { Signer, Contract } from "ethers";
import { TokenIdentifier, getTokensMetadata } from "../config/token/config";
import metalTokenArtifact from '../../artifacts/contracts/token/MetalToken.sol/MetalToken.json';

export async function main(tokenFactoryAddress: string, deployerAddress: string, feesManagerAddress: string, authorizationGuardAddress: string) {

    const tokenFactory = await ethers.getContractAt("TokenFactory", tokenFactoryAddress);
    const tokensMetadata = getTokensMetadata(deployerAddress, feesManagerAddress, authorizationGuardAddress);

    // Retrieve the addresses of the Gold and Silver tokens
    const goldTokenAddress = await tokenFactory.tokenForId(TokenIdentifier.Gold);
    const silverTokenAddress = await tokenFactory.tokenForId(TokenIdentifier.Silver);

    const tokenBeacon = await tokenFactory.tokenBeacon();

    console.log(`Gold MetalToken deployed at ${goldTokenAddress}`);
    console.log(`Silver MetalToken deployed at ${silverTokenAddress}`);

    try {
        console.log(`[verify-metalToken]: Attempting to verify Gold Token ${goldTokenAddress}...`)

        // Get MetalToken interface
        const abi = metalTokenArtifact.abi;
        const iface = new ethers.Interface(abi);

        // Verify the Gold Token proxy contract

        // Prepare gold token init data
        const goldParams = [
            tokensMetadata[TokenIdentifier.Gold].owner,
            tokensMetadata[TokenIdentifier.Gold].feesManager,
            tokensMetadata[TokenIdentifier.Gold].name,
            tokensMetadata[TokenIdentifier.Gold].symbol,
            tokensMetadata[TokenIdentifier.Gold].authorizationGuard
        ]
        const goldEncodedInitData = iface.encodeFunctionData("initialize", goldParams)
        console.log(`Golde encode init datav2:`, goldEncodedInitData)

        console.log(`params;`, goldParams)

        // Verify the Gold Token proxy contract
        await run("verify:verify", {
            address: goldTokenAddress,
            constructorArguments: [tokenBeacon, goldEncodedInitData],
        });
        console.log("Gold Token proxy contract verified successfully");

        console.log(`[verify-metalToken]: Attempting to verify Silver Token ${silverTokenAddress}...`)

        // Prepare silver token initdata
        const silverParams = [
            tokensMetadata[TokenIdentifier.Silver].owner,
            tokensMetadata[TokenIdentifier.Silver].feesManager,
            tokensMetadata[TokenIdentifier.Silver].name,
            tokensMetadata[TokenIdentifier.Silver].symbol,
            tokensMetadata[TokenIdentifier.Silver].authorizationGuard
        ];

        const silverEncodedInitData = iface.encodeFunctionData("initialize", silverParams)

        await run("verify:verify", {
            address: silverTokenAddress,
            constructorArguments: [tokenBeacon, silverEncodedInitData],
        });
        console.log("Silver Token proxy contract verified successfully");

        // Fetch the implementation contract address from the beacon
        const beaconAddress = await tokenFactory.tokenBeacon();
        const implementationAddress = await upgrades.erc1967.getImplementationAddress(beaconAddress);

        console.log(`[verify-metalToken]: Attempting to verify Metal Token Implementation ${implementationAddress}...`)

        // Verify the implementation contract
        await run("verify:verify", {
            address: implementationAddress,
            constructorArguments: [],
        });
        console.log("Implementation contract verified successfully");

    } catch (error) {
        console.error("Verification failed:", error);
    }
}


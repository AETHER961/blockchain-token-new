import { ethers, run } from "hardhat";
import { getTokensMetadata } from "../config/token/config";

//npx hardhat run scripts/verify/verify-metaltoken.ts  --network sepolia
export async function main(contractAddress: string, feesManagerAddress: string, authorizationGuardAddress: string, beaconAddress: string) {
    console.log(`starting to verify token factory!!!!!!!!!!!!!!`, {
        contractAddress, feesManagerAddress, authorizationGuardAddress, beaconAddress
    })
    const abiCoder = new ethers.AbiCoder();
    // const contractAddress = "0x55db44a93f66FbdDfDa05a7110211Dc171cE769D";
    const deployerAddress = "0xf3d14044A5B809019bF41390e93Da4B8ad3338C9";
    // const feesManagerAddress = "0x60C53bb274a4F5222b85a744789ec21c69B48079"
    // const authorizationGuardAddress = "0x501D042bEE6acb3F3c303A6d50348F2345F8466E"
    // const beaconAddress = "0x2D12Ef8398350DC2fcEe285EF432214DFca800fE"

    const tokensMetadata = getTokensMetadata(deployerAddress, feesManagerAddress, authorizationGuardAddress);


    // Define the structure of TokenInitParam
    const tokenInitParamType = [
        "tuple(uint256 tokenId, address owner, address feesManager, string name, string symbol, address authorizationGuard)"
    ];

    // Encode the array of objects
    const initTokensEncoded = abiCoder.encode([`${tokenInitParamType}[]`], [tokensMetadata]);

    // Encode the constructor arguments
    // const constructorArguments = abiCoder.encode(
    //     ["address", "address", `${tokenInitParamType}[]`],
    //     [owner, tokenBeacon, initTokens]
    // );

    const tokenMetadata = {
        owner: deployerAddress,
        feesManager: feesManagerAddress,
        name: tokensMetadata[0].name,
        symbol: tokensMetadata[0].symbol,
        authorizationGuard: tokensMetadata[0].authorizationGuard
    }
    try {
        // for (const tokenMetadata of tokensMetadata) {
        // try {

        const abiCoder = new ethers.AbiCoder();

        // Encode the initializer parameters
        const initData = abiCoder.encode(
            ["address", "address", "string", "string", "address"],
            [tokenMetadata.owner, tokenMetadata.feesManager, tokenMetadata.name, tokenMetadata.symbol, tokenMetadata.authorizationGuard]
        );
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: [
                deployerAddress,
                beaconAddress,
                tokensMetadata
            ],
        });
        console.log("Contract verified successfully");
        // } catch (error) {
        //     console.error("Verification failed:", error);
        // }

        // }

    } catch (error) {
        console.error("Verification failed:", error);
    }
}

// main()
//     .then(() => process.exit(0))
//     .catch((error) => {
//         console.error(error);
//         process.exit(1);
//     });

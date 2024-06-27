import { ethers, run } from "hardhat";
import { getTokensMetadata } from "../config/token/config";

//npx hardhat run scripts/verify/verify-metaltoken.ts  --network sepolia
export async function main(contractAddress: string, feesManagerAddress: string, authorizationGuardAddress: string, beaconAddress: string, deployerAddress: string) {

    const tokensMetadata = getTokensMetadata(deployerAddress, feesManagerAddress, authorizationGuardAddress);

    try {

        try {
            await run("verify:verify", {
                address: contractAddress,
                constructorArguments: [
                    deployerAddress,
                    beaconAddress,
                    tokensMetadata
                ],
            });
            console.log("Contract verified successfully");
            return true;
        } catch (error) {
            console.error("Verification failed:", error);
            return false;
        }



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

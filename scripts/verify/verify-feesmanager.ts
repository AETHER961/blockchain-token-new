import { ethers, run } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

export async function main(contractAddress: string) {

    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: [],
        });

        const implementationAddress = await getImplementationAddress(ethers.provider, contractAddress);

        // Verify the implementation contract
        await run("verify:verify", {
            address: implementationAddress,
            constructorArguments: [],
        });
        console.log("Contract verified successfully");
    } catch (error) {
        console.error("Verification failed:", error);
    }
}

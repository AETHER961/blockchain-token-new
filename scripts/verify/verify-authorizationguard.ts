import { ethers, run } from "hardhat";
import { getFeeWallet } from "../helpers/env";

//npx hardhat run scripts/verify/verify-multisigvalidation.ts --network sepolia
export async function main(contractAddress: string, tokenManager: string) {
    const [deployer, backendWallet] = await ethers.getSigners();

    const admins = [deployer.address];
    const authorizedAccounts = [deployer.address, backendWallet.address]
    const trustedContracts = [tokenManager]

    console.log(`Constructor args:`, {
        constructorArguments: [
            admins,
            authorizedAccounts,
            trustedContracts,
        ],
    })
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: [
                admins,
                authorizedAccounts,
                trustedContracts,
            ],
        });
        console.log("Contract verified successfully");
        return true;
    } catch (error) {
        console.error("Verification failed:", error);
        return false;
    }
}

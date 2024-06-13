import { run } from "hardhat";

//npx hardhat run scripts/verify/verify-tokenmanager.ts  --network sepolia
export async function main(contractAddress: string, tokenFactoryAddress: string, feesManagerAddress: string, multiSigValidationAddress: string, authorizationGuardAddress: string) {
    // const contractAddress = "0xeF1f6A4dFb38e5b0eBa942a1aD01230f30d68326";
    // const tokenFactoryAddress = "0x11D0Dc295578EAC25479E4c0eb9910e5b08952E1";
    // const feesManagerAddress = "0x60C53bb274a4F5222b85a744789ec21c69B48079";
    const admins = ["0xf3d14044A5B809019bF41390e93Da4B8ad3338C9"];
    const authorizedAccounts = ["0xf3d14044A5B809019bF41390e93Da4B8ad3338C9", "0xf6BC3bF697bBDD5D810d4681AFB884E3FCDcc34d"];
    // const multiSigValidationAddress = "0xED24c72DfD37A6Be2912AF249Aa2734f65FFCeE6";
    // const authorizationGuardAddress = "0x501D042bEE6acb3F3c303A6d50348F2345F8466E";

    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: [
                tokenFactoryAddress,
                feesManagerAddress,
                admins,
                authorizedAccounts,
                multiSigValidationAddress,
                authorizationGuardAddress
            ],
        });
        console.log("Contract verified successfully");
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

import { run } from "hardhat";

//npx hardhat run scripts/verify/verify-multisigvalidation.ts --network sepolia
async function main() {
    const contractAddress = "0xED24c72DfD37A6Be2912AF249Aa2734f65FFCeE6";
    const authorizationGuardAddress = "0x501D042bEE6acb3F3c303A6d50348F2345F8466E";

    const mintSigners = [
        { signerAddress: "0xCBA19FC71b5C474e6726D18e7Ab380aea7eA64fD", roleName: "Warehouse admin" },
        { signerAddress: "0x56FcBC342D35ce908201407CA9cE6620BCcc4d9C", roleName: "Director" },
        { signerAddress: "0xC415B176F90C46EFe64dCB2608DF5394Aa36C49C", roleName: "Token manager" },
        { signerAddress: "0xff7774DC7FB785e41F5C0e04AF7db78897dC131f", roleName: "Auditor" },
    ];

    const releaseSigners = [
        { signerAddress: "0xff7774DC7FB785e41F5C0e04AF7db78897dC131f", roleName: "Auditor" },
    ];


    // const signers = [
    //     "0xCBA19FC71b5C474e6726D18e7Ab380aea7eA64fD",
    //     "0x56FcBC342D35ce908201407CA9cE6620BCcc4d9C",
    //     "0xC415B176F90C46EFe64dCB2608DF5394Aa36C49C",
    //     "0xff7774DC7FB785e41F5C0e04AF7db78897dC131f",
    // ];


    // const roles = [
    //     "Warehouse admin",
    //     "Director",
    //     "Token manager",
    //     "Auditor",
    // ];

    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: [
                authorizationGuardAddress,
                mintSigners,
                releaseSigners,
            ],
        });
        console.log("Contract verified successfully");
    } catch (error) {
        console.error("Verification failed:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

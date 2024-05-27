import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("mintAndLockTokens", "Calls the mintAndLockTokens function")
    .addParam("contract", "The address of the TokenManager contract")
    .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
        const [deployer] = await hre.ethers.getSigners();
        const contractAddress = taskArgs.contract;

        const TokenManager = await hre.ethers.getContractFactory("TokenManager");
        const tokenManager = TokenManager.attach(contractAddress) as any;

        const messages = [
            {
                account: deployer.address,
                weight: 1,
                metalId: 0,
                signatureHash: "0x26f2ad3d0ee19fa805aba27e879d9a3392124c05e2cf96b0a0a68af3211cd25a",
                signatures: ["0x830dc308c7c84b0020ecbef2899a9252aef6ef538aa0bfa76ebcb5264f9f08e26bc36d2d839c1209f71f77917bb2d3b15146d35b7cccd629aa3dbfe5fe4c1ed31c"],
                roleIndices: [0],
            },
        ];

        const tx = await tokenManager.mintAndLockTokens(messages);
        await tx.wait();

        console.log("Transaction hash:", tx.hash);
    });

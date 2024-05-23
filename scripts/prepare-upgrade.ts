import { ethers } from "hardhat";
import * as deployment from "./helpers/deploy";
import { getContractAddress } from "./helpers/utils";

const prepareUpdate = async (): Promise<void> => {
    const [deployer] = await ethers.getSigners();
    const chainId = (await ethers.provider.getNetwork()).chainId;

    console.log(`Preparing Collection contract upgrade with the account:`, deployer.address);
    console.log(
        `Account balance:`,
        (await ethers.provider.getBalance(deployer.address)).toString(),
    );

    await deployment.prepareUpdate(deployer, getContractAddress(chainId, `Collection_V1`));
};

prepareUpdate().catch(error => {
    console.error(error);
    process.exitCode = 1;
});

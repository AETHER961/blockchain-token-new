import { ethers } from "hardhat";
import { getContractAddress } from "../helpers/utils";

import * as deployment from "../helpers/deploy";

export const upgradeTokenBeacon = async (): Promise<void> => {
    const [deployer] = await ethers.getSigners();
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const beacon = getContractAddress(chainId, `MetalToken`);

    await deployment.upgradeTokenBeacon(deployer, beacon);
    console.log(`Upgraded MetalToken beacon implementation`);
};

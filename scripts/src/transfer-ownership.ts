import { ethers, upgrades } from "hardhat";
import { getContractAddress, trackTransaction } from "../helpers/utils";
import { getOwner } from "../helpers/env";
import upgradeableBeaconArtifact from "@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol/UpgradeableBeacon.json";

// Because Ownable2Step is used by BridgeMediator and FeesManager,
// the ownership transfer requires for pending owner to accept the ownership
// for all the contracts by calling `acceptOwnership` function.
// Transferring ownership over ProxyAdmin does not require previosly mentioned step.
export const transferOwnership = async (): Promise<void> => {
    const [deployer] = await ethers.getSigners();
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const pendingOwner = getOwner();

    console.log(`Transferring contracts ownership from the account:`, deployer.address);
    console.log(`Pending owner: `, pendingOwner);

    const bridgeMediator = await ethers.getContractAt(
        `BridgeMediator`,
        getContractAddress(chainId, `BridgeMediator`),
        deployer,
    );

    const feesManager = await ethers.getContractAt(
        `FeesManager`,
        getContractAddress(chainId, `FeesManager`),
        deployer,
    );

    const tokenFactory = await ethers.getContractAt(
        `TokenFactory`,
        getContractAddress(chainId, `TokenFactory`),
        deployer,
    );

    const metalTokenBeacon = await ethers.getContractAtFromArtifact(
        upgradeableBeaconArtifact,
        getContractAddress(chainId, `MetalTokenBeacon`),
        deployer,
    );

    const goldToken = await ethers.getContractAt(
        `MetalToken`,
        getContractAddress(chainId, `GoldToken`),
        deployer,
    );

    const silverToken = await ethers.getContractAt(
        `MetalToken`,
        getContractAddress(chainId, `SilverToken`),
        deployer,
    );

    await upgrades.admin.transferProxyAdminOwnership(pendingOwner);

    await trackTransaction(
        bridgeMediator.transferOwnership(pendingOwner),
        `Transfers ownership of BridgeMediator contract`,
    );

    await trackTransaction(
        feesManager.transferOwnership(pendingOwner),
        `Transfers ownership of FeesManager contract`,
    );

    await trackTransaction(
        tokenFactory.transferOwnership(pendingOwner),
        `Transfers ownership of TokenFactory contract`,
    );

    await trackTransaction(
        metalTokenBeacon.transferOwnership(pendingOwner),
        `Transfers ownership of MetalToken beacon contract`,
    );

    await trackTransaction(
        goldToken.transferOwnership(pendingOwner),
        `Transfers ownership of GoldToken contract`,
    );

    await trackTransaction(
        silverToken.transferOwnership(pendingOwner),
        `Transfers ownership of SilverToken contract`,
    );
};

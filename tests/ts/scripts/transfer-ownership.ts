import { expect } from "chai";
import { Contract } from "ethers";
import { getOwner } from "../../../scripts/helpers/env";
import { getContract } from "../../../scripts/helpers/utils";
import { fullDeploy } from "../../../scripts/src/full-deploy";
import { transferOwnership } from "../../../scripts/src/transfer-ownership";
import { TokenIdentifier } from "../../../scripts/config/token/config";
import { ethers } from "hardhat";

// @audit BOGDAN STEFAN Does not work properly when runned locally, as it will delete OpenZeppelin's manifest file and upgrade will fail because of that
describe(`Transfer Ownership tests`, async () => {
    const pendingOwner = getOwner();

    let bridgeMediator: Contract;
    let feesManager: Contract;
    let tokenFactory: Contract;
    let goldToken: Contract;
    let silverToken: Contract;
    let upgradeableBeacon: Contract;

    before(async () => {
        await fullDeploy();
        await transferOwnership();

        bridgeMediator = await getContract(`BridgeMediator`);
        feesManager = await getContract(`FeesManager`);
        tokenFactory = await getContract(`TokenFactory`);
        upgradeableBeacon = await getContract(`MetalToken`);
        goldToken = await ethers.getContractAt(
            `MetalToken`,
            await tokenFactory.tokenForId(TokenIdentifier.Gold),
        );
        silverToken = await ethers.getContractAt(
            `MetalToken`,
            await tokenFactory.tokenForId(TokenIdentifier.Silver),
        );
    });

    describe(`Ownership transfer`, () => {
        it(`Should properly set pending owner`, async () => {
            expect(await bridgeMediator.pendingOwner()).to.be.equal(pendingOwner);
            expect(await feesManager.pendingOwner()).to.be.equal(pendingOwner);
            expect(await tokenFactory.pendingOwner()).to.be.equal(pendingOwner);
            expect(await upgradeableBeacon.pendingOwner()).to.be.equal(pendingOwner);
            expect(await goldToken.pendingOwner()).to.be.equal(pendingOwner);
            expect(await silverToken.pendingOwner()).to.be.equal(pendingOwner);
        });
    });
});

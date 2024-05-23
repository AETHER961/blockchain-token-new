import { ethers } from "hardhat";

export const getAMBContract = (): string => {
    const ambContract = process.env.AMB_CONTRACT;

    if (ambContract === undefined || !ethers.isAddress(ambContract))
        throw new Error(`AMB_CONTRACT is not set`);
    return ambContract;
};

export const getForeignMediator = (): string => {
    const foreignMediator = process.env.FOREIGN_MEDIATOR;

    if (foreignMediator !== undefined && ethers.isAddress(foreignMediator)) {
        return foreignMediator;
    } else {
        return ethers.ZeroAddress;
    }
};

export const getFeeWallet = (): string => {
    const feeWallet = process.env.FEE_WALLET;

    if (feeWallet === undefined || !ethers.isAddress(feeWallet))
        throw new Error(`FEE_WALLET is not set`);
    return feeWallet;
};

export const getOwner = (): string => {
    const owner = process.env.OWNER;

    if (owner === undefined || !ethers.isAddress(owner)) throw new Error(`OWNER is not set`);
    return owner;
};

export const getFeeRate = (): bigint => {
    const txFeeRate = process.env.TX_FEE_RATE;

    if (txFeeRate === undefined) throw new Error(`FEE_RATE is not set`);
    return BigInt(txFeeRate);
};

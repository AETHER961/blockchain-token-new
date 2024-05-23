import { IncomingMessageRoutingParamStruct } from "../../../types/lib/agau-common/contracts/bridge/BridgeMediator";
import { ethers } from "hardhat";
import { AddressLike } from "ethers";

export interface RoutingConfigGenerateParams {
    tokenManager: AddressLike;
}

export async function generateIncomingRoutingConfig(
    params: RoutingConfigGenerateParams,
): Promise<IncomingMessageRoutingParamStruct[]> {
    const tokenManagerIface = (await ethers.getContractFactory(`TokenManager`)).interface;

    return [
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`mintAndLockTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`releaseTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`burnTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`refundTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`freezeTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`unfreezeTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`seizeTokens`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`createDiscountGroup`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`updateDiscountGroup`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`setUserDiscountGroup`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`updateTransactionFeeRate`)!.selector,
        },
        {
            target: params.tokenManager,
            selector: tokenManagerIface.getFunction(`updateFeeAmountRange`)!.selector,
        },
    ];
}

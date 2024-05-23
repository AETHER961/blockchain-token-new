// import { TokenFactory } from "../../../types";
import { AddressLike } from "ethers";
import { TokenInitParamStruct } from "../../helpers/deploy";

export enum TokenIdentifier {
    Gold = 0,
    Silver = 1,
}

export const getTokensMetadata = (
    owner: AddressLike,
    feesManager: AddressLike,
    authorizationGuardAddress: AddressLike
): TokenInitParamStruct[] => {
    return [
        {
            owner: owner,
            feesManager: feesManager,
            tokenId: TokenIdentifier.Gold,
            name: `AgAu Gold`,
            symbol: `AGOLD`,
            authorizationGuard: authorizationGuardAddress
        },
        {
            owner: owner,
            feesManager: feesManager,
            tokenId: TokenIdentifier.Silver,
            name: `AgAu Silver`,
            symbol: `ASLVR`,
            authorizationGuard: authorizationGuardAddress
        },
    ];
};

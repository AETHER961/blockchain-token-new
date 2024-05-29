export interface CommonOpMessage {
    account: string;
    weight: number;
    // Metal identifier
    metalId: number;
    documentHash: string;
    // Message Hash
    signatureHash: string;
    // Submitted signatures
    signatures: string[];
    // Signer index in roles array
    roleIndices: number[];
}
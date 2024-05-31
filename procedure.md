### Mint and Lock Tokens

To mint and lock new Gold or Silver tokens, interact with the `mintAndLockTokens` function from the `TokenManager` contract.

Overview steps:
* Sign message with all necessary signer wallets
* Submit message and signatures to mintAndLockTokens function

Detailed steps:
FE Client:
1. To retrieve the message hash, call the `getMessageHashCommon` from the `MultiSigValidation` contract:

* Function signature:
```
function getMessageHashCommon(string memory functionName, CommonTokenOpSignatureData memory message)
```

* Message content:

```
struct CommonTokenOpSignatureData {
    // Account address message is referred to
    address account;
    // Total amount of the metal (in grams)
    uint48 weight;
    // Metal identifier
    uint8 metalId;
    // Hash of the document to sign
    string documentHash;
}
```

e.g. 
```
getMessageHashCommon("mintAndLockTokens", {
    account: "TOKEN-RECEIVER-ADDRESS",
    weight: 1000,
    metalId: 0,
    documentHash: "DOCUMENT-HASH"
})
```
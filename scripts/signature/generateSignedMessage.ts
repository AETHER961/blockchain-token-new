import { ethers } from "hardhat";

// Connect to the Ethereum provider
const provider = ethers.getDefaultProvider('sepolia'); // or your preferred network

// Private key for signing (replace with your own)
const privateKey1 = process.env.PRIVATE_KEY1 || "";
const privateKey2 = process.env.PRIVATE_KEY2 || "";
const privateKey3 = process.env.PRIVATE_KEY3 || "";
const wallet1 = new ethers.Wallet(privateKey1, provider);
const wallet2 = new ethers.Wallet(privateKey2, provider);
const wallet3 = new ethers.Wallet(privateKey3, provider);

console.log(`Wallet:`, wallet1.address);

const signers = [
    wallet1,
    wallet2,
    wallet3
]

// Define the message components
const account = '0x4bCcF85a1F9d1814f5493FAb068f338dF0aC0518';
const weight = 1; // uint48
const metalId = 0; // uint8
// const nonce = 0;

// Create the message hash
function hashMessageMintAndLockTokens(account: string, weight: number, metalId: number
    // , nonce: number
) {
    const abiCoder = new ethers.AbiCoder();
    return ethers.solidityPackedKeccak256(
        // abiCoder.encode(
        ['string', 'address', 'uint48', 'uint8', 'uint256'],
        ['mintAndLockTokens', account, weight, metalId
            // , nonce
        ]
        // )
    );
}

// Create the message hash
const messageHash = hashMessageMintAndLockTokens(account, weight, metalId
    // , nonce
);
console.log('Message Hash:', messageHash);

// Sign the message hash using `eth_personalSign`
async function signMessage(hash: string, wallet: any) {
    const signature = await wallet.signMessage(ethers.getBytes(hash));
    return signature;
}

// Generate and sign the prefixed hash
async function signPrefixedMessage(hash: string, wallet: any) {
    const abiCoder = new ethers.AbiCoder();
    const prefixedMessage = ethers.solidityPackedKeccak256(
        // abiCoder.encode(
        ['string', 'bytes32'],
        ['\x19Ethereum Signed Message:\n32', hash]
        // )

    );
    console.log(`Prefiex message;`, prefixedMessage)
    return await signMessage(prefixedMessage, wallet);
}

for (let i = 0; i < signers.length; i++) {
    signPrefixedMessage(messageHash, signers[i]).then(async (signature) => {
        const addr = await signers[i].getAddress();
        console.log(`got sig for`, addr);
        console.log('Signature:', signature);
    });
}


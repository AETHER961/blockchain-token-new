export const networks: { [chainId: string]: NetworkNames } = {
    '11155111': 'sepolia',
    '1': 'ethereum',
    '97': 'bsc'
}
export type NetworkNames = 'bsc' | 'sepolia' | 'hardhat' | 'ethereum';

// Deployments are stored in a JSON file in the root of the project. This file may be
// updated after each deployment with the new contract addresses. It is segmented by
// network.

export type DeploymentContract = {
    name: string;
    address: string;
};

export type Deployment = {
    network: string;
    contracts: Array<DeploymentContract>;
};

export type Deployments = {
    deployments: Array<Deployment>;
};

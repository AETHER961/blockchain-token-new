# AgAu Token Protocol

The following is a brief description of the AgAu Token Protocol, which is a Layer 1 part of the AgAu project, contained from managment contracts deployed on Gnosis Chain and this repo, containing the tokens as the result of the actions of the management contracts.

## [Developer Guide](#developer-guide)

### [Directory Structure](#directory-structure)

```txt
scripts/
|- config/ - "Contract configuration files"
|- helpers/ - "Helper functions"
|- src/ - "Typescripts scripts"
contracts/ - "Solidity contracts"
|- bridge/ - "Contracts for interacting with the bridge"
|- token/ - "Token contracts"
|- management/ - "Management contracts"
tests/ - "Tests folder"
|- ts/ - "Typescript tests"
|- sol/ - "Solidity tests"
|-- gas/ - "Gas usage benchmark tests"
|-- scenarios/ - "Main scenarios for contracts used by gas and integration tests"
|-- scripts/ - "Scripts tests"
|-- unit/ - "Unit tests"
|-- BaseTest.t.sol - "Base smart contract for the gas and integration tests"
|-- Constants.t.sol - "Constants for the gas and integration tests"
.env.example - "Example environment vars"
.eslintignore - "Ignore list for eslint"
.eslintrc - "Configure eslint"
.gitignore - "Ignore list for Git"
.gitmodules - "Git submodules"
.prettierignore - "Ignore list for Prettier"
.prettierrc.json - "Configure Prettier"
.solhint.json - "Solidity linter configuration"
deployments.json - "Contract deployment addresses per network"
foundry.toml - "Foundry configuration"
hardhat.config.ts - "Hardhat configuration"
package-lock.json - "Node dependencies lock"
package.json - "Node dependencies"
remappings.json - "Solidity remappings for Hardhat and Foundry"
slither.config.json - "Configure Slither"
tsconfig.json - "Configure Typescript"
```

--- *(not an extensive list of all files)* ---

&nbsp;

## [Frameworks used](#frameworks-used)

#### [Foundry](https://book.getfoundry.sh)

Foundry is being used the most during development cycle for testing and debugging. 

Configuration details can be found in [foundry.toml](./foundry.toml).

#### [Hardhat](https://hardhat.org/getting-started/)

Hardhat is being used for utility tasks, such as documentation generation, as well as for deployment.

Configuration details can be found in [hardhat.config.ts](./hardhat.config.ts), which inherits from [foundry.toml](./foundry.toml).

&nbsp;

## [External dependencies](#external-dependencies)

#### [Gnosis AMB Bridge](https://docs.gnosischain.com/bridges/tokenbridge/amb-bridge/)

Gnosis AMB Bridge is being used for cross-chain communication between L2 and L1 protocol contracts and vice versa. The bridge is predeployed on couple of networks and the proper configuration of `.env` file is needed to properly interact with it.

#### [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

OpenZeppelin contracts are being used whereever aplicable where its functionality matches the needs of the protocol. This is also due to not reimplement some of the functionalities, which are already tested and audited.

#### [OpenZeppelin Upgrades](https://github.com/OpenZeppelin/openzeppelin-upgrades)

OpenZeppelin upgrades are being used for the upgradeability of the protocol contracts.

### [Project setup](#project-setup)

#### [Clone the repository](#clone-the-repository)

```sh
git clone https://github.com/agau-company/blockchain-token-new --recursive
```

If you forget to clone with `--recursive`, you can run `git submodule update --init --recursive` to get the submodules.

#### [Install Node.js / NPM](#install-nodejs--npm)

```sh
npm install -g npm
```

#### [Install Foundry](#install-foundry)

```sh
curl -L https://foundry.paradigm.xyz | bash
```

#### [Create a new `.env` file by copying the `.env.example`](#copy-over-a-new-env-file)

Make sure the environment variables are set properly.

```sh
cp .env.example .env
```

The variables description is the following:

| Variable| Description |
|-|-|
| VERIFY_CONTRACTS | Flag to verify contracts on Etherscan |
| MNEMONIC | Mnemonic phrase for wallet |
| ETHERSCAN_API_KEY | API key for Etherscan. Mandatory only for verify |
| AMB_CONTRACT | Address of the AMB bridge contract |
| FOREIGN_MEDIATOR | Optional address of the `BridgeMediator` on other side of the bridge |
| FEE_WALLET | Address of the wallet fees will be send to |
| OWNER | Address of the owner of the contracts |
| TX_FEE_RATE | Initial transaction fee rate (takes into consideration denominator of 100_000) |
| TENDERLY_FORK_URL | URL of the Tenderly fork |
| TENDERLY_USERNAME | Tenderly username |
| TENDERLY_PROJECT_NAME | Tenderly project name |
| SEPOLIA_NODE_URL | Sepolia node URL |
| ETHEREUM_RPC_URL | Ethereum RPC URL |

#### [Install Node dependencies](#install-node-dependencies)

```sh
npm ci
```

&nbsp;

## [Available commands and tasks](#commands-and-tasks)

There are a dozen of the commands available in the [package.json](./package.json) file, but here are the most common and useful ones:

#### [Run the tests with Forge](#run-the-unit-tests-with-forge)

```sh
npm run test:unit
```

This will run everything in [test/unit](./test/), which utilizes [Forge](https://book.getfoundry.sh/forge/tests) to test contract code.

You can also run integration and benchmark tests, as well as tests for scripts.

#### [Check the code coverage](#code-coverage)

```sh
npm run coverage
```

#### [Generate Typescript types](#typechain)

```sh
npm run typechain
```

Generates a typings based on the smart contract, which will enforce usage of the correct types in the code. This is done automatically after the instalation of the dependencies and later on can be triggered manually.

#### [Deploy the contracts to desired network](#deploy-to-network)

Create a [.env](./.env) file matching the variables seen in [.env.example](./.env.example).
Also, the proper network configuration must be set in [hardhat.config.ts](./hardhat.config.ts).
In order to properly configure the contracts, the [config](./scripts/config) folder must be updated with the correct values.

For this protocol specifically, [configuration of the incoming bridge messages routing](./scripts/config/bridge/config.ts) is needed to properly configure contracts interacting with the bridge.


After everything is configured, the following command should be run:

```sh
npm run full-deploy <NETWORK_NAME>
```

This will automatically update [deployments.json](./deployments.json), which gets exported with your [NPM package](./package.json).

#### [Generate documentation](#generate-documentation)

```sh
forge doc --build
```

Sets up API docs from the [NatSpec](https://docs.soliditylang.org/en/latest/natspec-format.html) comments in your contract interfaces (ignoring implementations and libraries).

If desired, this can be updated to included all contract comments, and the path can be updated to a different location (such as if you want a seperate `docs` repository for your project).

&nbsp;

## [Deployments](#deployments)

All contract addresses for each network are stored in [deployments.json](./deployments.json).

&nbsp;

## [GitHub Actions](#github-actions)

This repository comes with couple of [GitHub Actions](https://github.com/features/actions) configured. They can be found in the [./github/workflows](./.github/workflows/) directory. These will run the [Tests](./.github/workflows/test.yaml), [Lint Check](./.github/workflows/lint.yaml), etc, during Pull Requests and merges to the master branch.

&nbsp;

## [License](#license)

The code in this project is unlicensed.

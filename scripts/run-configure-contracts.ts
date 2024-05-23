import { configureContracts } from "./src/configure-contracts";

configureContracts().catch(error => {
    console.error(error);
    process.exitCode = 1;
});

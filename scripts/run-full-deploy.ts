import { fullDeploy } from "./src/full-deploy";

fullDeploy().catch(error => {
    console.error(error);
    process.exitCode = 1;
});

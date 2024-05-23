import { fullDeploy } from "./src/deploy-v2";

fullDeploy().catch(error => {
    console.error(error);
    process.exitCode = 1;
});

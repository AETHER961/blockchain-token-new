import { upgradeTokenBeacon } from "./src/upgrade-token-beacon";

upgradeTokenBeacon().catch(error => {
    console.error(error);
    process.exitCode = 1;
});

import { transferOwnership } from "./src/transfer-ownership";

transferOwnership().catch(error => {
    console.error(error);
    process.exitCode = 1;
});

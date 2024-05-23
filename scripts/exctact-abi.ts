import fs from "fs";

/* extract ABI file from compiler output
```
   npx ts-node ./exctract-abi.ts
```
writes to ./abi folder.
Contracts need to be compiled first.
*/

const filenames = [`MetalToken`, `TokenFactory`, `TokenManager`, `FeesManager`, `BridgeMediator`];

console.log(`Extracting of the ABIs initiated`);

filenames.forEach(filename => {
    const artifactPath = `./out/`;

    if (!fs.existsSync(artifactPath)) {
        console.log(`err`, `No artifacts folder found`);
        return;
    }

    const file = artifactPath + filename + `.sol/` + filename + `.json`;
    fs.readFile(file, `utf-8`, (err, data) => {
        if (err) {
            console.log(`err`, err);
            return;
        }

        const abi = JSON.parse(data).abi;
        const destPath = `./abi/`;

        if (!fs.existsSync(destPath)) {
            fs.mkdirSync(destPath);
        }

        fs.writeFile(destPath + filename + `.json`, JSON.stringify(abi), err => {
            if (err) {
                console.log(`err`, err);
                return;
            }
        });
    });
});

console.log(`Done!`);
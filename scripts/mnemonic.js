const { ethers } = require("hardhat");

const bip39 = require('bip39');
const signale = require('signale');

// Generate a mnemonic (seed phrase) using the bip39 package
async function main() {

    const mnemonic = await bip39.generateMnemonic();

    signale.await('Generating mnemonic...');
    signale.success(mnemonic);

    return mnemonic;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exitCode = 1;
});

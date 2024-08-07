
const { ethers, utils } = require("hardhat");
require('dotenv').config();

async function main() {
  try {

    const wallet = await ethers.getSigners();
    const walletSigner = wallet[3];

    console.log("Wallet Address:", walletSigner);


    // Get the ContractFactory of your SimpleContract
    const Rhino = await ethers.getContractAt("EFYFinance", process.env.CONTRACT_ADDRESS, walletSigner);

    // Retrieve the updated message
    const updatedMessage = await Rhino.unstake(0);

    console.log("Stake Message from Wallet:", updatedMessage.from);
    console.log("Stake Message hash:", updatedMessage.hash);

  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

main();

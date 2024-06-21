
const { ethers, network } = require("hardhat");
const {Signale} = require('signale');
const fs = require("fs");
const path = require("path");

const signale_options = {
  disabled: false,
  interactive: false,
  logLevel: 'info',
  scope: 'rhinostec/deploy',
  secrets: [],
  stream: process.stdout,
  types: {
    wallet: {
      badge: '💰',
      color: 'green',
      label: 'wallet',
      logLevel: 'info'
    }
  }
};

require('dotenv').config();

async function main() {

	const provider = ethers.provider;
	const loggin = new Signale(signale_options);

	// Get the contract owner
	const contractOwner = await ethers.getSigners();
	const contractAddress = {
		"owner": contractOwner[0].address,
		"seedSales": contractOwner[1].address,
		"privateSales": contractOwner[2].address,
		"publicSales": contractOwner[3].address,
		"ecoSystem": contractOwner[4].address,
		"team": contractOwner[5].address,
		"advisors": contractOwner[6].address,
		"marketing": contractOwner[7].address,
		"treasury": contractOwner[8].address,
		"airdrop": contractOwner[9].address,
		"staking": contractOwner[10].address,
	}
	loggin.info(`Deploying contract from: ${contractAddress.owner}`);

	// Hardhat helper to get the ethers contractFactory object
	const Rhino = await ethers.getContractFactory('EFYFinance');
	
	// get balance from address and show in console
	const balance = await provider.getBalance(contractAddress.owner);

	loggin.info(`Wallet balance: ${ethers.formatUnits(balance)}`);

	// Get the contract name, symbol and total supply from the environment file
	let _contractName = process.env.CONTRACT_NAME;
	let _contractSymbol = process.env.CONTRACT_SYMBOL;
	let _contractSupply = process.env.CONTRACT_TOTAL_SUPPLY;

	loggin.info(`Contract Name: ${_contractName}`);
	loggin.info(`Contract Symbol: ${_contractSymbol}`);

	console.log('\n');

	loggin.wallet(`Seed Sales: ${contractAddress.seedSales}`);
	loggin.wallet(`Private Sales: ${contractAddress.privateSales}`);
	loggin.wallet(`Public Sales: ${contractAddress.publicSales}`);
	loggin.wallet(`Ecosystem Development: ${contractAddress.ecoSystem}`);
	loggin.wallet(`Team: ${contractAddress.team}`);
	loggin.wallet(`Advisors: ${contractAddress.advisors}`);
	loggin.wallet(`Marketing: ${contractAddress.marketing}`);
	loggin.wallet(`Treasury: ${contractAddress.treasury}`);
	loggin.wallet(`Airdrop: ${contractAddress.airdrop}`);
	loggin.wallet(`Staking: ${contractAddress.staking}`);

	console.log('\n');

	loggin.await(`Deploying ${_contractName}...`);

	const memoryAddress = [
		contractAddress.seedSales, // Seed Sales
		contractAddress.privateSales, // Private Sales
		contractAddress.publicSales,	// Public Sales
		contractAddress.ecoSystem,	// Ecosystem Development
		contractAddress.team,	// Team
		contractAddress.advisors, // Advisors
		contractAddress.marketing, // Marketing
		contractAddress.treasury, // Treasury
		contractAddress.airdrop, // Airdrop
		contractAddress.staking // Staking
	]

	// Calculate the estimate gas cost for deployment
	 const deploymentData = Rhino.interface.encodeDeploy([
    _contractName,
    _contractSymbol,
    _contractSupply,
    memoryAddress,
  ]);

  const estimatedGas = await ethers.provider.estimateGas({
    data: deploymentData,
  });

	const gasPrice = (await ethers.provider.getFeeData()).gasPrice;
	const gasCost = BigInt(estimatedGas) * BigInt(gasPrice);

	loggin.info(`Estimated deployment cost: ${ethers.formatUnits(gasCost)} ETH`);
	
	const rhinoToken = await Rhino.deploy(_contractName, 
										_contractSymbol, 
										_contractSupply,
										memoryAddress);

	await rhinoToken.waitForDeployment();

	let deployedAddress = await rhinoToken.getAddress();
	loggin.success(`${_contractName} deployed to: ${deployedAddress}`)

	console.log('\n');

	const constructorArgs = [
		_contractName,
		_contractSymbol,
		_contractSupply,
		memoryAddress
	];

	// Verify the contract on Etherscan
	loggin.await(`Generating constructor arguments...`);

	const constructorArgsPath = path.resolve(__dirname, "../cache/constructor-args.json");
	fs.writeFileSync(constructorArgsPath, JSON.stringify(constructorArgs, null, 2), "utf8");
	loggin.success("Constructor arguments saved to: constructor-args.json");

	console.log(`
Succesfully deployed contract: 
To submit the contract for verification, run the following command:
npx hardhat verify --network ${network.name} ${deployedAddress} --constructor-args ${constructorArgsPath}
	`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exitCode = 1;
});

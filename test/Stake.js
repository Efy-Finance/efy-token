const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

require('dotenv').config();

/**
 * @title Rhinostec
 * @custom:security-contact rhinostec.com
 */

describe("Stake Tests / EFYFinance", function () {

  async function deployToken() {
    const Token = await ethers.getContractFactory("EFYFinance");
    const contractOwner = await ethers.getSigners();

    const contractAddress = {
      "owner": contractOwner[0],
      "seedSales": contractOwner[1],
      "privateSales": contractOwner[2],
      "publicSales": contractOwner[3],
      "ecoSystem": contractOwner[4],
      "team": contractOwner[5],
      "advisors": contractOwner[6],
      "marketing": contractOwner[7],
      "treasury": contractOwner[8],
      "airdrop": contractOwner[9],
      "staking": contractOwner[10],
	  }

    const memoryAddress = [
      contractAddress.seedSales.address, // Seed Sales
      contractAddress.privateSales.address, // Private Sales
      contractAddress.publicSales.address,	// Public Sales
      contractAddress.ecoSystem.address,	// Ecosystem Development
      contractAddress.team.address,	// Team
      contractAddress.advisors.address, // Advisors
      contractAddress.marketing.address, // Marketing
      contractAddress.treasury.address, // Treasury
      contractAddress.airdrop.address, // Airdrop
      contractAddress.staking.address // Staking
    ]

    let _contractName = process.env.CONTRACT_NAME;
    let _contractSymbol = process.env.CONTRACT_SYMBOL;
    let _contractSupply = process.env.CONTRACT_TOTAL_SUPPLY;

    const rhinoToken = await Token.deploy(_contractName, 
										_contractSymbol, 
										_contractSupply,
										memoryAddress);
    await rhinoToken.waitForDeployment();

    // Fixtures can return anything you consider useful for your tests
    return { Token, rhinoToken, contractAddress};
  }

  it("check if the accrued interest is correct", async function () {
    const { rhinoToken, contractAddress } = await loadFixture(deployToken);

    const interestRate = BigInt(20000); // 20% annual interest rate
    const amount = BigInt(1000) * BigInt(10 ** 18); // 1000 EFY

    // Set the annual interest rate
    await rhinoToken.connect(contractAddress.owner).setAnnualInterestRate(interestRate);

    // Stake 1000 EFY from ecoSystem
    await rhinoToken.connect(contractAddress.ecoSystem).stake(amount);

    // Simulate one year passing
    const yearInSeconds = 365 * 24 * 60 * 60;
    await ethers.provider.send("evm_increaseTime", [yearInSeconds]);
    await ethers.provider.send("evm_mine");

    // Retrieve stakes and calculate expected interest
    const [, , , accruedInterest] = await rhinoToken.connect(contractAddress.ecoSystem).getStakes(contractAddress.ecoSystem.address);
    
    // The contract formula for one year should be: (amount * interestRate * 365 days) / (365 days * INTEREST_RATE_SCALE)
    const INTEREST_RATE_SCALE = BigInt(100000); // Scale for interest rate
    const yearInSeconds2 = BigInt(365 * 24 * 60 * 60)
    const secondsPerYear = BigInt(365 * 24 * 3600); // Seconds in a year as BigInt
    const expectedInterest = (amount * interestRate * yearInSeconds2) / (secondsPerYear * INTEREST_RATE_SCALE);

    console.log("Expected interest (from test calculation): ", ethers.formatUnits(expectedInterest));
    console.log("Accrued interest (from contract): ", ethers.formatUnits(accruedInterest[0]));

    expect(accruedInterest[0]).to.be.closeTo(expectedInterest, 100);  // Allow a small variance
});



});

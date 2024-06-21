require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ganache");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: {mnemonic: process.env.MNEMONIC_DEV}
    },
    hardhat: {
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC,
      accounts: {
        mnemonic: process.env.MNEMONIC
      }
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.bnbchain.org:8545",
      gasPrice: 20000000000,
      chainId: 97,
      accounts: {
        mnemonic: process.env.MNEMONIC
      }
    },
    mainnet: {
      url: "https://eth.rhinostec.com/v1/mainnet",
      accounts: {mnemonic: process.env.MNEMONIC}
    }
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_SECRET,
      sepolia: process.env.ETHERSCAN_SECRET,
      goerli: process.env.ETHERSCAN_SECRET,
    }
  },
  sourcify: {
    enabled: true
  },
  solidity: "0.8.8",
};

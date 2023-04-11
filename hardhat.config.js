/**  
* @type import('hardhat/config').HardhatUserConfig  
*/  
require('@nomiclabs/hardhat-ethers'); 
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
      chainId: 1337,
      mnemonic: [process.env.HARDHAT_MNEMONIC]
    },
    ganache: {
      url: "http://127.0.0.1:8545",
      accounts: [
        `0x981f101912bc24E882755A6DD8015135D0cc4D4D`,
      ],
    }
  }
};



module.exports = {
  defaultNetwork: "xdc",
  networks: {
    hardhat: {
    },
    xdc: {
      url:  "http://127.0.0.1:8545",
      accounts: [process.env.HARDHAT_MNEMONIC]
    }
  },
  solidity: {
    version: "^0.8.2",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/types";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  // networks:{
  //   hardhat:{
  //     forking: {
  //       url: "https://rpc-mainnet.kcc.network"
  //     }
  //   }
  // },
  solidity: {
    compilers: [{
      version: "0.8.4", settings: {
        optimizer: {
          enabled: true,
        }
      }
    },
    //just for testing
    {
      version: "0.6.12",
      settings: {}
    },
    {
      version: "0.6.6",
      settings: {}
    },
    {
      version: "0.5.16",
      settings: {}
    },
    {
      version: "0.4.20",
      settings: {}
    }
    ],
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true,
    spacing: 2
  }
};

export default config;
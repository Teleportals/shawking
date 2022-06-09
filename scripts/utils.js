const hre = require("hardhat");
const fs = require("fs");

const deploymentsPath = `${hre.config.paths.root}/scripts/deployed.json`;

const aaveV3Mappings = {
  // Rinkeby
  WETH: {
    address: "0xd74047010D77c5901df5b0f9ca518aED56C85e8D",
    aToken: "0x608D11E704baFb68CfEB154bF7Fd641120e33aD4",
    debtToken: "0x252C97371c9Ad590898fcDb0C401d9230939A78F",
  },
  WBTC: {
    address: "0x124F70a8a3246F177b0067F435f5691Ee4e467DD",
    aToken: "0xeC1d8303b8fa33afB59012Fc3b49458B57883326",
    debtToken: "0x3eA8e63b6e7260C2D6cfc3877914cbB6eE687D6B",
  },
  USDC: {
    address: "0xb18d016cDD2d9439A19f15633005A6b2cd6Aa774",
    aToken: "0x50b283C17b0Fc2a36c550A57B1a133459F4391B3",
    debtToken: "0x0EfFd205184FE944f9eF80264b144270dB15eEa7",
  },
};

const aaveV2Mappings = {
  // Kovan
  WETH: {
    address: "0xd0A1E359811322d97991E03f863a0C30C2cF029C",
    aToken: "0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347",
    debtToken: "0xDD13CE9DE795E7faCB6fEC90E346C7F3abe342E2",
  },
  WBTC: {
    address: "0xD1B98B6607330172f1D991521145A22BCe793277",
    aToken: "0x9b8107B86A3cD6c8d766B30d3aDD046348bf8dB4",
    debtToken: "0x62538022242513971478fcC7Fb27ae304AB5C29F",
  },
  USDC: {
    address: "0xe22da380ee6B445bb8273C81944ADEB6E8450422",
    aToken: "0xe12AFeC5aa12Cf614678f9bFeeB98cA9Bb95b5B0",
    debtToken: "0xBE9B058a0f2840130372a81eBb3181dcE02BE957",
  },
};

const compoundMappings = {
  // Kovan
  ETH: {
    address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    cToken: "0x41b5844f4680a8c38fbb695b7f9cfd1f64474a72",
  },
  WBTC: {
    address: "0xd3A691C852CDB01E281545A27064741F0B7f6825",
    cToken: "0xa1faa15655b0e7b6b6470ed3d096390e6ad93abb",
  },
  USDC: {
    address: "0xb7a4F3E9097C08dA09517b5aB877F7a917224ede",
    cToken: "0x4a92e71227d294f041bd82dd8f78591b75140d63",
  },
};

const sampleAmounts = {
  collateralAmmount: hre.ethers.utils.parseUnits("5", 8), // assuming WBTC
  debtAmount: hre.ethers.utils.parseUnits("10000", 6), // assuming USDC
}

const updateDeployments = async (chain, newDeployData) => {
  let deployData = [];
  if (fs.existsSync(deploymentsPath)) {
    deployData = JSON.parse(fs.readFileSync(deploymentsPath).toString());
    let chainData = deployData.find(e => e.chain == chain);
    const index = deployData.findIndex(e => e == chainData);
    deployData[index] = newDeployData;
  } else {
    deployData.push(newDeployData);
  }
  fs.writeFileSync(deploymentsPath, JSON.stringify(deployData, null, 2));
};

const readDeployments = async (chain) => {
  let deployData;
  if (fs.existsSync(deploymentsPath)) {
    deployData = JSON.parse(fs.readFileSync(deploymentsPath).toString());
    let chainData = deployData.find(e => e.chain == chain);
    if (!chainData) {
      return chainData;
    } else {
      throw `No deployed data for chain ${chain} found!`;
    }
  } else {
    throw 'no /scripts/deployed.json file found!';
  }
}

const checkChain = async (chainNameCheck) => {
  // let wallet = await hre.ethers.getSigner();
  // let provider = wallet.provider;
  // console.log(provider);
  // let chainName;
  // if(!provider.network.name) {
  //   chainName = 'unknown';
  // } else {
  //   chainName = provider.network.name;
  // }
  // if (chainName != chainNameCheck || chainName != 'unknown') {
  //   throw 'Chain name mismatch, check proper chain passed and you are running the correct chain script! "npx hardhat --network chainName run ./script/script_chainname.js"';
  // }
}


module.exports = {
  updateDeployments,
  readDeployments,
  checkChain,
  aaveV3Mappings,
  aaveV2Mappings,
  compoundMappings,
  sampleAmounts
}
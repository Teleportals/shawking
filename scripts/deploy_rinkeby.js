const hre = require("hardhat");

const aaveV3Mappings = {
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

const providers = {
  rinkeby: {
    aavev3: {
      pool: "0xE039BdF1d874d27338e09B55CB09879Dedca52D8",
      dataProvider: "0xBAB2E7afF5acea53a43aEeBa2BA6298D8056DcE5",
    },
  },
};

async function main() {
  const Teleporter = await hre.ethers.getContractFactory("Teleporter");
  const teleporter = await Teleporter.deploy(
    "0x2307Ed9f152FA9b3DcDfe2385d279D8C2A9DF2b0"
  );

  await teleporter.deployed();
  console.log("Teleporter deployed to:", teleporter.address);

  const AaveV3 = await hre.ethers.getContractFactory("AaveV3");
  const aavev3 = await AaveV3.deploy(
    teleporter.address,
    providers.rinkeby.aavev3.pool,
    providers.rinkeby.aavev3.dataProvider
  );

  await aavev3.deployed();
  console.log("AaveV3 deployed to:", aavev3.address);

  let tx;
  for (const asset of Object.values(aaveV3Mappings)) {
    tx = await aavev3.addATokenMapping(asset.address, asset.aToken);
    await tx.wait();
    tx = await aavev3.addDebtTokenMapping(asset.address, asset.debtToken);
    await tx.wait();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

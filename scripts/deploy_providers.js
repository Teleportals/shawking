const hre = require("hardhat");

const providers = {
  rinkeby: {
    aavev3: {
      pool: "0x87530ED4bd0ee0e79661D65f8Dd37538F693afD5",
      dataProvider: "0xBAB2E7afF5acea53a43aEeBa2BA6298D8056DcE5",
    },
  },
  kovan: {
    compound: {}
  }
};

async function main() {
  // const AaveV3 = await hre.ethers.getContractFactory("AaveV3");
  // const aavev3 = await AaveV3.deploy(
  //   providers.rinkeby.aavev3.pool,
  //   providers.rinkeby.aavev3.pool,
  //   providers.rinkeby.aavev3.dataProvider
  // );

  // await aavev3.deployed();

  // console.log("AaveV3 deployed to:", aavev3.address);

  const Compound = await hre.ethers.getContractFactory("Compound");
  const compound = await compound.deploy(
    providers.rinkeby.aavev3.pool,
  );

  await compound.deployed();

  console.log("Compound deployed to:", compound.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

const hre = require("hardhat");
const fs = require("fs");

const {updateDeployments, aaveV3Mappings} = require("./utils");

const CHAIN_NAME='rinkeby';
const CONNEXT_RINKEBY_HANDLER = "0x2307Ed9f152FA9b3DcDfe2385d279D8C2A9DF2b0";

const providers = {
  rinkeby: {
    aavev3: {
      pool: "0xE039BdF1d874d27338e09B55CB09879Dedca52D8",
      dataProvider: "0xBAB2E7afF5acea53a43aEeBa2BA6298D8056DcE5",
    },
  },
};

const main = async() => {
  const Teleporter = await hre.ethers.getContractFactory("Teleporter");
  const teleporter = await Teleporter.deploy(
    CONNEXT_RINKEBY_HANDLER
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
  console.log("AaveV3 asset mappings ready!");

  let newdeployData = {
    chain: CHAIN_NAME,
    connextDomainId: 1111,
    teleporter: {address: teleporter.address},
    loanProvider: {address: aavev3.address}
  }

  await updateDeployments(CHAIN_NAME, newdeployData);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

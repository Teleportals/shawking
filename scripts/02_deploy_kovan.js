const hre = require("hardhat");
const fs = require("fs");
const {updateDeployments, aaveV2Mappings, connextParams} = require("./utils");

const CHAIN_NAME='kovan';
const CONNEXT_KOVAN_HANDLER = connextParams.kovan.handler;

const providers = {
  kovan: {
    aavev2: {
      pool: "0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe",
      dataProvider: "0x3c73A5E5785cAC854D468F727c606C07488a29D6",
    },
  },
};

const main = async() => {
  console.log(CHAIN_NAME);
  const Teleporter = await hre.ethers.getContractFactory("Teleporter");
  const teleporter = await Teleporter.deploy(
    CONNEXT_KOVAN_HANDLER
  );

  await teleporter.deployed();
  console.log("Teleporter deployed to:", teleporter.address);

  // const Compound = await hre.ethers.getContractFactory("Compound");
  // const compound = await Compound.deploy(teleporter.address);
  // await compound.deployed();
  // console.log("Compound deployed to:", compound.address);
  // let tx;
  // for (const asset of Object.values(compoundMappings)) {
  //   tx = await compound.addCTokenMapping(asset.address, asset.cToken);
  //   await tx.wait();
  // }

  const AaveV2 = await hre.ethers.getContractFactory("AaveV2");
  const aavev2 = await AaveV2.deploy(
    teleporter.address,
    providers.kovan.aavev2.pool,
    providers.kovan.aavev2.dataProvider
  );

  await aavev2.deployed();
  console.log("AaveV2 deployed to:", aavev2.address);

  let tx;
  for (const asset of Object.values(aaveV2Mappings)) {
    tx = await aavev2.addATokenMapping(asset.address, asset.aToken);
    await tx.wait();
    tx = await aavev2.addDebtTokenMapping(asset.address, asset.debtToken);
    await tx.wait();
  }
  console.log("AaveV2 asset mappings ready!");

  let newdeployData = {
    chain: CHAIN_NAME,
    connextDomainId: connextParams.kovan.domainId,
    teleporter: {address: teleporter.address},
    loanProvider: {address: aavev2.address}
  };

  await updateDeployments(CHAIN_NAME, newdeployData);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

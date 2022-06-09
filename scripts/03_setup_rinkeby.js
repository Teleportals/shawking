const hre = require("hardhat");
const fs = require("fs");

const { readDeployments, checkChain } = require("./utils");

const CHAIN_NAME='rinkeby';

const main = async () => {
  await checkChain(CHAIN_NAME);
  const deployedRinkebyData = await readDeployments("rinkeby");
  const deployedKovanData = await readDeployments("kovan");

  // Get rinkeby teleporter
  const local = deployedRinkebyData;
  console.log(`...setting up the ${CHAIN_NAME} Teleporter`);
  const teleporter = await hre.ethers.getContractAt("Teleporter", local.teleporter.address);
  let tx1 = await teleporter.setLoanProvider(local.connextDomainId, local.loanProvider.address, true);
  await tx1.wait();
  console.log(`...recorded ${local.chain} loan provider`);

  const ref = deployedKovanData;
  let tx2 = await teleporter.setLoanProvider(ref.connextDomainId, ref.loanProvider.address, true);
  await tx2.wait();
  console.log(`...recorded ${ref.chain} loan provider`);
  let tx3 = await teleporter.setTeleporter(ref.connextDomainId, ref.teleporter.address);
  await tx3.wait();
  console.log(`...recorded ${ref.chain} teleporter`);



}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
const hre = require("hardhat");
const fs = require("fs");

const { readDeployments, aaveV2Mappings } = require("./utils");

const CHAIN_NAME = 'kovan';

const CONNEXT_KOVAN_TEST_TOKEN = "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9";

const main = async () => {
  const deployedRinkebyData = await readDeployments("rinkeby");
  const deployedKovanData = await readDeployments("kovan");

  // Get kovan teleporter
  const local = deployedKovanData;
  console.log(`...setting up the ${CHAIN_NAME} Teleporter`);
  const teleporter = await hre.ethers.getContractAt("Teleporter", local.teleporter.address);
  let tx = await teleporter.setLoanProvider(local.connextDomainId, local.loanProvider.address, true);
  await tx.wait();
  console.log(`...recorded ${local.chain} loan provider`);
  
  const ref = deployedRinkebyData;
  tx = await teleporter.setLoanProvider(ref.connextDomainId, ref.loanProvider.address, true);
  await tx.wait();
  console.log(`...recorded ${ref.chain} loan provider`);
  tx = await teleporter.setTeleporter(ref.connextDomainId, ref.teleporter.address);
  await tx.wait();
  console.log(`...recorded ${ref.chain} teleporter`);

  console.log(`...setting connext ${CHAIN_NAME} test token ${CONNEXT_KOVAN_TEST_TOKEN}`);
  tx = await teleporter.setTestToken(CONNEXT_KOVAN_TEST_TOKEN);
  tx.wait();
  console.log(`...test token set complete!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
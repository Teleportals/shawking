require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs");

const { readDeployments, connextParams, testParams } = require("./utils");

const CHAIN_A_NAME = 'rinkeby'; // initiation chain
const CHAIN_B_NAME = "kovan"; // receiving chain

const CHAIN_A_COLLATERAL_ASSET = testParams.testAssets.rinkeby.collateral;
const CHAIN_B_COLLATERAL_ASSET = testParams.testAssets.kovan.collateral;

const CHAIN_A_DEBT_ASSET = testParams.testAssets.rinkeby.debt;
const CHAIN_B_DEBT_ASSET = testParams.testAssets.kovan.debt;

const main = async () => {
  const local = await readDeployments(CHAIN_A_NAME);
  const remote = await readDeployments(CHAIN_B_NAME);

  if (!process.env.TEST_USER_PKEY) {
    throw "Please set TEST_USER_PKEY in ./root/.env"
  }
  const testUser = new hre.ethers.Wallet(process.env.TEST_USER_PKEY, hre.ethers.provider);

  const teleporter = await hre.ethers.getContractAt("Teleporter", local.teleporter.address);

  // execute xcall with Connext
  console.log(`...begin 'completeLoanTransfer()' xcall on ${CHAIN_B_NAME} teleporter`);
  let tx = await teleporter.connect(testUser).completeLoanTransfer(
    connextParams.rinkeby.domainId, // originDomain
    remote.loanProvider.address, // loanProvider Chain B
    CHAIN_B_COLLATERAL_ASSET, // collateral asset Chain B
    testParams.testAmounts.collateralAmount,
    CHAIN_B_DEBT_ASSET, // collateral asset Chain B
    testParams.testAmounts.debtAmount,
    testUser.address
  );
  await tx.wait();
  console.log(`...xcall received!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
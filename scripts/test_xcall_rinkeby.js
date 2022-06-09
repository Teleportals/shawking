require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs");

const CHAIN_NAME = 'rinkeby';
const { readDeployments, testParams } = require("./utils");

const COLLATERAL_ASSET_USED = testParams.testAssets.rinkeby.collateral;
const COLLATERAL_RECEIPT_TOKEN = testParams.testAssets.rinkeby.collateralReceiptToken;
const DEBT_ASSET_USED = testParams.testAssets.rinkeby.debt;
const ADDRESS_ZERO = hre.ethers.constants.AddressZero;

const main = async () => {
  const deployedRinkebyData = await readDeployments(CHAIN_NAME);
  const local = deployedRinkebyData;

  if (!process.env.TEST_USER_PKEY) {
    throw "Please set TEST_USER_PKEY in ./root/.env"
  }
  const testUser = new hre.ethers.Wallet(process.env.TEST_USER_PKEY, hre.ethers.provider);

  const teleporter = await hre.ethers.getContractAt("Teleporter", local.teleporter.address);
  // const aaveV3provider = await hre.ethers.getContractAt("AaveV3", local.loanProvider.address);
  // const realAaveV3 = await hre.ethers.getContractAt("IAaveV3Pool", await aaveV3provider.aavePool());
  // const debtToken = await hre.ethers.getContractAt("IERC20Mintable", DEBT_ASSET_USED);
  // const collatToken = await hre.ethers.getContractAt("IERC20Mintable", COLLATERAL_ASSET_USED);

  // execute xcall with Connext
  console.log(`...'initiateLoanTransfer()' xcall on ${CHAIN_NAME} teleporter `);
  let tx = await teleporter.connect(testUser).initiateLoanTransfer()

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
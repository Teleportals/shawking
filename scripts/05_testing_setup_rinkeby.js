require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs");

const CHAIN_NAME = 'rinkeby';

const { readDeployments, testParams } = require("./utils");

const COLLATERAL_ASSET = testParams.testAssets.rinkeby.collateral;
const COLLATERAL_AMOUNT = testParams.testAmounts.collateralAmount;
const COLLATERAL_RECEIPT_TOKEN = testParams.testAssets.rinkeby.collateralReceiptToken;
const DEBT_ASSET = testParams.testAssets.rinkeby.debt;
const DEBT_AMOUNT = testParams.testAmounts.debtAmount;
const LIQUIDITY_AMOUNT = testParams.testAmounts.liquidityAmount;

const ADDRESS_ZERO = hre.ethers.constants.AddressZero;

const main = async () => {
  console.log(CHAIN_NAME);
  const local = await readDeployments(CHAIN_NAME);

  if (!process.env.TEST_USER_PKEY) {
    throw "Please set TEST_USER_PKEY in ./root/.env"
  }
  const testUser = new hre.ethers.Wallet(process.env.TEST_USER_PKEY, hre.ethers.provider);

  const teleporter = await hre.ethers.getContractAt("Teleporter", local.teleporter.address);
  const aaveV3provider = await hre.ethers.getContractAt("AaveV3", local.loanProvider.address);
  const realAaveV3 = await hre.ethers.getContractAt("IAaveV3Pool", await aaveV3provider.aavePool());
  const debtToken = await hre.ethers.getContractAt("IERC20Mintable", DEBT_ASSET);
  const collatToken = await hre.ethers.getContractAt("IERC20Mintable", COLLATERAL_ASSET);

  // Support collateral-debt pair asset on teleporter
  console.log(`...setting collateral-debt pair on ${CHAIN_NAME} teleporter`);
  let tx = await teleporter.setSupportedPair(COLLATERAL_ASSET, DEBT_ASSET);
  tx.wait();
  console.log(`...collateral-debt pair set complete!`);

  // Add liquidity to the sending teleporter
  console.log(`...adding liquidity to the sending ${CHAIN_NAME} teleporter (0/3)`);
  tx = await debtToken.mint(LIQUIDITY_AMOUNT);
  await tx.wait();
  console.log(`...minted collateral for deployer complete (1/3)!`);
  tx = await debtToken.approve(teleporter.address, LIQUIDITY_AMOUNT);
  await tx.wait();
  console.log(`...erc20 collateral approved complete (2/3)!`);
  tx = await teleporter.addLiquidity(debtToken.address, LIQUIDITY_AMOUNT, ADDRESS_ZERO);
  await tx.wait();
  console.log("...adding liquidity complete (3/3)!");

  // Open debt position for test user
  console.log(`...creating debt position for test user (0/4)`);
  tx = await collatToken.connect(testUser).mint(COLLATERAL_AMOUNT);
  await tx.wait();
  console.log(`...minted collateral for test user complete (1/4)!`);
  tx = await collatToken.connect(testUser).approve(realAaveV3.address, COLLATERAL_AMOUNT);
  await tx.wait();
  console.log(`...erc20 collateral approved complete (2/4)!`);
  tx = await realAaveV3.connect(testUser).supply(collatToken.address, COLLATERAL_AMOUNT, testUser.address, 0);
  await tx.wait();
  console.log(`...deposit on lending provider complete (3/4)!`);
  tx = await realAaveV3.connect(testUser).borrow(debtToken.address, DEBT_AMOUNT, 2, 0, testUser.address, {gasLimit: 8000000});
  await tx.wait();
  console.log(`...test user debt position set complete (4/4)!`);

  // test user approves transfer of aToken asset
  console.log(`...waiting for test user to approves transfer of aToken asset`);
  const aToken = await hre.ethers.getContractAt("IERC20", COLLATERAL_RECEIPT_TOKEN)
  tx = await aToken.connect(testUser).approve(aaveV3provider.address, await aToken.balanceOf(testUser.address));
  await tx.wait();
  console.log(`...test user to approve transfer of aToken asset complete!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
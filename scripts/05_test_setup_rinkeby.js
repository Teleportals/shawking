require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs");

const CHAIN_NAME = 'rinkeby';
const CONNEXT_RINKEBY_TEST_TOKEN = "0x3FFc03F05D1869f493c7dbf913E636C6280e0ff9";

const { readDeployments, checkChain, aaveV3Mappings, sampleAmounts } = require("./utils");

const COLLATERAL_ASSET_USED = aaveV3Mappings.WBTC.address;
const DEBT_ASSET_USED = aaveV3Mappings.USDC.address;

const ADDRESS_ZERO = hre.ethers.constants.AddressZero;

const main = async () => {
  await checkChain(CHAIN_NAME);

  const deployedRinkebyData = await readDeployments(CHAIN_NAME);
  const local = deployedRinkebyData;

  if (!process.env.TEST_USER_PKEY) {
    throw "Please set TEST_USER_PKEY in ./root/.env"
  }
  const testUser = new hre.ethers.Wallet(process.env.TEST_USER_PKEY);

  const teleporter = await hre.ethers.getContractAt("Teleporter", local.teleporter.address);
  const aaveV3provider = await hre.ethers.getContractAt("AaveV3", local.loanProvider.address);
  const realAaveV3 = await hre.ethers.getContractAt("IAaveV3Pool", await aaveV3provider.aavePool());
  const debtToken = await hre.ethers.getContractAt("IERC20Mintable", DEBT_ASSET_USED);
  const collatToken = await hre.ethers.getContractAt("IERC20Mintable", COLLATERAL_ASSET_USED);

  // Support collateral-debt pair asset on teleporter
  console.log(`...setting collateral-debt pair on ${CHAIN_NAME} teleporter`);
  let tx = await teleporter.setSupportedPair(COLLATERAL_ASSET_USED, DEBT_ASSET_USED);
  tx.wait();
  console.log(`...collateral-debt pair set complete!`);
  console.log(`...setting connext ${CHAIN_NAME} test token ${CONNEXT_RINKEBY_TEST_TOKEN}`);
  tx = await teleporter.setTestToken(CONNEXT_RINKEBY_TEST_TOKEN);
  tx.wait();
  console.log(`...test token set complete!`);


  // Add liquidity to the sending teleporter
  console.log(`...adding liquidity to the sending ${CHAIN_NAME} teleporter`);
  tx = await debtToken.mint(sampleAmounts.debtAmount);
  await tx.wait();
  tx = await debtToken.approve(teleporter.address, sampleAmounts.debtAmount);
  await tx.wait();
  tx = await teleporter.addLiquidity(teleporter.address, sampleAmounts.debtAmount);
  await tx.wait();
  console.log("..adding liquidity complete!");

  // Open debt position for test user
  console.log(`...creating debt position for test user!`);
  tx = await collatToken.connect(testUser).mint(sampleAmounts.collateralAmmount);
  await tx.wait();
  tx = await collatToken.connect(testUser).approve(realAaveV3.address, sampleAmounts.collateralAmmount);
  await tx.wait();
  tx = await realAaveV3.connect(testUser).supply(collatToken.address, sampleAmounts.collateralAmmount, ADDRESS_ZERO, 0);
  await tx.wait();
  const smallerAmount = sampleAmounts.debtAmount.div(hre.ethers.BigNumber.from("10"));
  tx = await realAaveV3.connect(testUser).borrow(debtToken.address, smallerAmount, ADDRESS_ZERO, 0);
  await tx.wait();
  console.log(`...test user debt position set complete!`);

  // test user approves transfer of aToken asset
  console.log(`...waiting for test user to approves transfer of aToken asset`);
  const aToken = await hre.ethers.getContractAt("IERC20", aaveV3Mappings.WBTC.aToken)
  tx = await aToken.connect(testUser).approve(aaveV3provider.address, await aToken.balanceOf(testUser.address));
  await tx.wait();
  console.log(`...test user to approve transfer of aToken asset complete!`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
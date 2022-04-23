// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const CONNEXT_RINKEBY = "0x3e99898Da8A01Ed909976AF13e4Fa6094326cB10";
const CONNEXT_KOVAN = "0xb10aCCbea65532bB2C45Adb34Da5b89A2A0f67b9";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Teleporter = await hre.ethers.getContractFactory("Teleporter");
  const tele = await Teleporter.deploy(CONNEXT_KOVAN);

  await tele.deployed();

  console.log("Teleporter deployed to:", tele.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

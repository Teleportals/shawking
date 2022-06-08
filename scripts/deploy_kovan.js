const hre = require("hardhat");

// const compoundMappings = {
//   ETH: {
//     address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
//     cToken: "0x41b5844f4680a8c38fbb695b7f9cfd1f64474a72",
//   },
//   WBTC: {
//     address: "0xd3A691C852CDB01E281545A27064741F0B7f6825",
//     cToken: "0xa1faa15655b0e7b6b6470ed3d096390e6ad93abb",
//   },
//   USDC: {
//     address: "0xb7a4F3E9097C08dA09517b5aB877F7a917224ede",
//     cToken: "0x4a92e71227d294f041bd82dd8f78591b75140d63",
//   },
// };

async function main() {
  const Teleporter = await hre.ethers.getContractFactory("Teleporter");
  const teleporter = await Teleporter.deploy(
    "0x3366A61A701FA84A86448225471Ec53c5c4ad49f"
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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

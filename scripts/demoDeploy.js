const hre = require("hardhat");

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;
  const infoPrice = hre.ethers.utils.parseEther("0.001");

  //Deploy Asset
  const Asset = await hre.ethers.getContractFactory("Asset");
  const asset = await Asset.deploy("URI");
  await asset.deployed();

  //Deploy Forwad Contract
  const Forward = await hre.ethers.getContractFactory("Asset");
  const forward = await Forward.deploy("URI");
  await forward.deployed();

  //Print Both Contract Addresses
  console.log("Asset Contract Deployed");
  console.log(asset.address);
  console.log("Forward Contract Deployed");
  console.log(forward.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

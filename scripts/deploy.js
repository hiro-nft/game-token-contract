// scripts/deploy.js
const { ethers,upgrades } = require("hardhat");
require('dotenv').config();

const hiroAddress = process.env.DEF_HIROTOEKN_ADDR;

async function main () {
  // We get the contract to deploy
  const Mid = await ethers.getContractFactory('Middle2Token');
  console.log('Deploying Game-Token... :', Mid);
  instance = await upgrades.deployProxy(Mid,["Middle3","MID3",hiroAddress,100000000,100000000]);
  await instance.deployed();
  console.log('Middle Token deployed to:', instance.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

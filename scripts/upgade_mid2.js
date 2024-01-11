const { ethers, upgrades } = require("hardhat");
require('dotenv').config();

const gameTokenAddress = process.env.DEF_GAMETOEKN_ADDR;

async function main() {
  const HiroV2 = await ethers.getContractFactory("Middle2Token");
  const txs = [];
  const tx = await upgrades.upgradeProxy(gameTokenAddress, HiroV2);
  txs.push(tx);
  await Promise.all(txs.map(tx => tx.wait()));
  console.log("Middle2Token upgraded", tx);
  
  //const tx2 =  await upgrades.upgradeTo(tx.address)
  //console.log("Middle2Token upgradeTo", tx2);
}

main();

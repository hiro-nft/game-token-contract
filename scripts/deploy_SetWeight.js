const { ethers } = require("hardhat");
require('dotenv').config();

const gameTokenAddress = process.env.DEF_GAMETOEKN_ADDR;

async function setWeight() {
  const [sender] = await ethers.getSigners();

  const contract = await ethers.getContractAt('Middle2Token',gameTokenAddress, sender);

  const txs = [];

  const tx = await contract.setWeight(0x1, 0x1);
  txs.push(tx);

  await Promise.all(txs.map(tx => tx.wait()));

  console.log("set weihgt susscess");
}

setWeight();

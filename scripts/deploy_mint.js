const { ethers } = require("hardhat");
require('dotenv').config();

const gameTokenAddress = process.env.DEF_GAMETOEKN_ADDR;
const testWalletAddress = process.env.DEF_TESTWALLET_ADDR;

async function mint() {
  const [sender] = await ethers.getSigners();

  const contract = await ethers.getContractAt('Middle2Token',gameTokenAddress, sender);

const amountToSend = ethers.utils.parseUnits("10000", 18);

  const txs = [];

  const tx = await contract.mint(testWalletAddress, amountToSend);
  txs.push(tx);

  await Promise.all(txs.map(tx => tx.wait()));

  console.log("mint susscess");
}

mint();

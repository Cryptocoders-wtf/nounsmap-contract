import { ethers } from "hardhat";

async function main() {
  const nounsToken = "0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03"; //Nouns本家
// We get the contract to deploy
  const NounsToken = await ethers.getContractFactory("NounsToken");
  const descriptorContract = NounsToken.attach(nounsToken);

  const test1 = "0xf05a0497994a33f18aa378630BC674eFC77Ad557";//nakajima-san
  const block = 14975625;

  const data = await descriptorContract.getPriorVotes(test1,block);
  console.log(data);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

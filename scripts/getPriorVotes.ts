import { ethers } from "hardhat";

async function main() {
  const nounsToken = "0x1602155eB091F863e7e776a83e1c330c828ede19";
// We get the contract to deploy
  const NounsToken = await ethers.getContractFactory("NounsToken");
  const descriptorContract = NounsToken.attach(nounsToken);

  const test1 = "0x3e7311e0Fc89fA633433076be268ae007A1b827a";
  const test2 = "0xa9faf095619e8A1D8873F6a940eC5906513EE079"
  const block = 10939332;

  const data = await descriptorContract.getPriorVotes(test2,block);
  console.log(data);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

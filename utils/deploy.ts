import { ethers, network } from "hardhat";

const descriptor = "0x0cfdb3ba1694c2bb2cfacb0339ad7b1ae5932b63";
const seeder = "0xcc8a0fb5ab3c7132c1b2a0109142fb112c4ce515";    
export const developer = "0x3e7311e0Fc89fA633433076be268ae007A1b827a"; 
export const committee = "0x3e7311e0Fc89fA633433076be268ae007A1b827a"; 

const proxy = (network.name == "rinkeby") ?
    "0xf57b2c51ded3a29e6891aba85459d600256cf317":
    "0xa5409ec958c83c3f309868babaca7c86dcb077c1"; // openSea proxy


// 1 eth = 10**18
const priceSeed = {
  maxPrice:  String(10 ** 18), // 1 ether;
  minPrice:  String(5 * 10 ** 15), //  0.005 ether; = 5 * 10^-3
  priceDelta:  String(15 * 10 ** 15), // 0.015 ether; = 15 * 10^-2
  timeDelta: 60, // 1 minutes; 
  expirationTime: 90 * 60, // 90 minutes;
};
export const deploy:any = async (setWhitelist = true) => {
 
  const nounsTokenFactory = await ethers.getContractFactory("NounsToken");
  const authorityToken = await nounsTokenFactory.deploy(descriptor,seeder,developer,committee,priceSeed,proxy);
  await authorityToken.deployed();

  const contentsTokenFactory = await ethers.getContractFactory("ContentsToken");
  const contentsToken = await contentsTokenFactory.deploy(descriptor,seeder,developer,committee,priceSeed,proxy);
  await contentsToken.deployed();
  await contentsToken.addAuthority(authorityToken.address);

  return { contentsToken, authorityToken };
};
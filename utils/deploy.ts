import { ethers, network } from "hardhat";

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
  let i =0
  console.log(i++);
  const contentsTokenFactory = await ethers.getContractFactory("ContentsToken");
  const contentsToken = await contentsTokenFactory.deploy(developer,committee,priceSeed,proxy);
  await contentsToken.deployed();

  console.log(i++);
  const nounsTokenFactory = await ethers.getContractFactory("NounsToken");
  console.log(i++);

  let authorityToken;
  if((network.name == "hardhat")){
    const descriptor = "0x0cfdb3ba1694c2bb2cfacb0339ad7b1ae5932b63";
    const seeder = "0xcc8a0fb5ab3c7132c1b2a0109142fb112c4ce515";    
    const proxy = "0xa5409ec958c83c3f309868babaca7c86dcb077c1"; // openSea proxy
    authorityToken = await nounsTokenFactory.deploy(descriptor,seeder,developer,committee,priceSeed,proxy,{gasLimit: 9000000});
    console.log(i++);
    await authorityToken.deployed();  
    console.log(i++);
    await contentsToken.addAuthority(authorityToken.address);
  } 
  console.log(i++);
  if((network.name == "rinkeby")){
    const descriptor = "0x292c84894c1B86140A784eec99711d6007005f21";
    const seeder = "0x5bcc91c44bffa15c9b804a5fd30174e8da296a4b";
    const proxy = "0xf57b2c51ded3a29e6891aba85459d600256cf317";    
    authorityToken = await nounsTokenFactory.deploy(descriptor,seeder,developer,committee,priceSeed,proxy,{gasLimit: 9000000});
    console.log(i++);
    await authorityToken.deployed();  
    console.log(i++);
    await contentsToken.addAuthority(authorityToken.address);
    const nounsToken = "0x1602155eB091F863e7e776a83e1c330c828ede19"; //NounsLove    
    await contentsToken.addAuthority(nounsToken);
  }
  console.log(i++);

  if((network.name == "mainnet")){
    const nounsToken = "0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03"; //Nouns本家    
    await contentsToken.addAuthority(nounsToken);
  }
  console.log(i++);
  contentsToken.setWeb2("https://dev.nounsmap.com/p/");
  return { contentsToken, authorityToken };
};
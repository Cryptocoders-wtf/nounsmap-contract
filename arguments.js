

const developer = "0x3e7311e0Fc89fA633433076be268ae007A1b827a"; 
const committee = "0x3e7311e0Fc89fA633433076be268ae007A1b827a"; 

let descriptor;
let seeder;
let proxy;

if((network.name == "mainnet")){
  descriptor = "0x0cfdb3ba1694c2bb2cfacb0339ad7b1ae5932b63";
  seeder = "0xcc8a0fb5ab3c7132c1b2a0109142fb112c4ce515";
  proxy = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
}

if((network.name == "rinkeby")){
  descriptor = "0x292c84894c1B86140A784eec99711d6007005f21";
  seeder = "0x5bcc91c44bffa15c9b804a5fd30174e8da296a4b";
  proxy = "0xf57b2c51ded3a29e6891aba85459d600256cf317";    
}
// await deployer.deploy(NFT, minter, descriptor, seeder, developers, proxy);

// 1 eth = 10**18
const priceSeed = {
  maxPrice:  String(10 ** 18), // 0.01 ether; = 1 * 10^2
  minPrice:  String(5 * 10 ** 15), //  0.00005 ether; = 5 * 10^-5
  priceDelta:  String(15 * 10 ** 15), // 0.00015 ether; = 15 * 10^-5
  timeDelta: 60, // 1 minutes; 
  expirationTime: 90 * 60, // 90 minutes;
};

module.exports = [
    developer,
    committee,
    priceSeed,
    proxy
  ];
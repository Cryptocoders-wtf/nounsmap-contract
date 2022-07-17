

const committee = "0x4E4cD175f812f1Ba784a69C1f8AC8dAa52AD7e2B";

let descriptor;
let seeder;
let proxy;

if((network.name == "mainnet")){
  proxy = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
}

if((network.name == "rinkeby")){
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
    committee,
    priceSeed,
    proxy
  ];
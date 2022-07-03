import { expect } from "chai";
import { ethers } from "hardhat";
import { deploy, developer } from "../utils/deploy";

let authorityToken :any = null;
let contentsToken :any = null;
before(async () => {
  const result = await deploy(false);
  contentsToken = result.contentsToken;
  authorityToken = result.authorityToken;
});
const catchError = async (callback: any) => {
  try {
    await callback();
    console.log("success");
    return false;
  } catch(e:any) {
    // console.log(e.reason);
    return true;
  }
};
describe("BasicMint", function () {
  it("basic mint should be suceeded", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    expect(await contentsToken.balanceOf(owner.address)).to.equal(1);

  });
  it("test  function call", async function () {
    var options = { gasPrice: 0x1000000000, gasLimit: 0x100, nonce: 45, value: 0 };
    expect(await contentsToken.getCurrentToken()).to.equal(2);
  });
  it("test Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const testPhotoId=3;
    console.log(authorityToken.address,owner.address, addr1.address);
    const tx = await contentsToken.Mint(addr1.address,authorityToken.address,testPhotoId);
    const res = await tx.wait();
    expect(await contentsToken.balanceOf(addr1.address)).to.equal(1);
  });

});

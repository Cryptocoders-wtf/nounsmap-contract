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
  it("initial status check", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    expect(await contentsToken.balanceOf(owner.address)).equal(0);
    expect(await contentsToken.getCurrentToken()).equal(0);
  });
  it("basic Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const testPhotoId=3;
    console.log(authorityToken.address,owner.address, addr1.address);
    expect(await catchError(async ()=>{ await  contentsToken.tokenURI(testPhotoId); })).equal(true);
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId);
    const res = await tx.wait();
    expect(await contentsToken.balanceOf(addr1.address)).equal(1);
    const after = await contentsToken.tokenURI(testPhotoId)
    expect(after.startsWith("data:application")).equal(true);
    
  });

});

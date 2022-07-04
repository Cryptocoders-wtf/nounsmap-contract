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
  it("1st Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const testPhotoId="6oHFJbRhdqBpCseSVNOk";
    console.log(authorityToken.address,owner.address, addr1.address);
    expect(await catchError(async ()=>{ await  contentsToken.tokenURI(0); })).equal(true);
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId);
    const rc = await tx.wait();
    const event = rc.events.find((event:any) => event.event === 'ContentsCreated');
    const [id, seed] = event.args;   
    console.log(id,seed);     
    expect(await contentsToken.balanceOf(addr1.address)).equal(1);
    const after = await contentsToken.tokenURI(0)
    expect(after.startsWith("data:application")).equal(true);
    
  });
  it("2nd Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const testPhotoId="7efUr8hbGVQTpWDXXGLV";
    console.log(authorityToken.address,owner.address, addr1.address);
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId);
    const rc = await tx.wait();
    const event = rc.events.find((event:any) => event.event === 'ContentsCreated');
    const [id, seed] = event.args;   
    console.log(id,seed);     
    expect(await contentsToken.balanceOf(addr1.address)).equal(2);
    const after = await contentsToken.tokenURI(1)
    expect(after.startsWith("data:application")).equal(true);
    
  });

});

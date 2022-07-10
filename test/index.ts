import { expect } from "chai";
import { ethers } from "hardhat";
import { deploy, developer } from "../utils/deploy";

let authorityToken :any = null;
let contentsToken :any = null;

const assetBase:any = {
  group: "photo",
  category: "news",
  tag: "",
  width: 512, height: 512,
  minter: ""
};

const asset = Object.assign({}, assetBase);
asset.name = "testContents";
asset.metadata = new Uint8Array();
asset.description = "this is test contents";


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
    asset.soulbound = owner.address;
    console.log("11");
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId,asset);
    const rc = await tx.wait();
    console.log("12");
    const event = rc.events.find((event:any) => event.event === 'ContentsCreated');
    const [id] = event.args;   
    console.log(id);     
    expect(await contentsToken.balanceOf(addr1.address)).equal(1);
    console.log("13");
    const after = await contentsToken.tokenURI(0)
    console.log(after);
    expect(after.startsWith("data:application")).equal(true);
    
  });
  it("2nd Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const testPhotoId="7efUr8hbGVQTpWDXXGLV";
    console.log(authorityToken.address,owner.address, addr1.address);
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId,asset);
    const rc = await tx.wait();
    const event = rc.events.find((event:any) => event.event === 'ContentsCreated');
    const [id] = event.args;   
    console.log(id);     
    expect(await contentsToken.balanceOf(addr1.address)).to.equal(2);
    const after = await contentsToken.tokenURI(1)
    console.log(after);
    expect(after.startsWith("data:application")).to.equal(true);
    
  });
  it("tokenURL confirm", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const testPhotoId="6oHFJbRhdqBpCseSVNOk";
    const after = await contentsToken.tokenURI(0)
    const resJson = JSON.parse(Buffer.from(after.substr('data:application/json;base64,'.length) , "base64").toString());
    expect(resJson.image).to.equal("https://dev.nounsmap.com/p/" + testPhotoId);
  });

  it("AssetAttribute confirm", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const attr = await contentsToken.getAttributes(0)
    expect(attr.name).to.equal("testContents");
  });

});

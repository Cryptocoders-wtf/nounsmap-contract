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

const testPhotoId="6oHFJbRhdqBpCseSVNOk";
const testPhotoId2="7efUr8hbGVQTpWDXXGLV";

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
    expect(await contentsToken.getCurrentToken()).equal(1);
  });
  it("1st Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    console.log(authorityToken.address,owner.address, addr1.address);
    expect(await catchError(async ()=>{ await  contentsToken.tokenURI(1); })).equal(true);
    asset.soulbound = owner.address; 
    asset.creator = addr1.address; 
    console.log("11");
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId,asset);
    const rc = await tx.wait();
    console.log("12");
    const event = rc.events.find((event:any) => event.event === 'ContentsCreated');
    const [id] = event.args;   
    console.log(id);     
  });
  it("1st Mint result balancce", async function () {
    const [owner,addr1] = await ethers.getSigners();    
      expect(await contentsToken.balanceOf(addr1.address)).equal(1);
  });
  it("1st Mint result tokenURI", async function () {
    const after = await contentsToken.tokenURI(1)
    console.log(after);
    expect(after.startsWith("data:application")).equal(true);
  });
  it("1st Mint result getTokenId", async function () {
    const tokenID = await contentsToken.getTokenId(testPhotoId);
    expect(tokenID).equals(1);
  });
  it("1st Mint result getAttrSoulbound", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const ret = await contentsToken.getAttributes(1);
    console.log(ret);
    expect(ret.soulbound).equals(owner.address);
    expect(ret.creator).equals(addr1.address);
  });
  it("2nd Mint", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    console.log(authorityToken.address,owner.address, addr1.address);
    const tx = await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId2,asset);
    const rc = await tx.wait();
    const event = rc.events.find((event:any) => event.event === 'ContentsCreated');
    const [id] = event.args;   
    console.log(id);     
    expect(await contentsToken.balanceOf(addr1.address)).to.equal(2);
  });

  it("same ContentsID mint should fail", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    console.log(authorityToken.address,owner.address, addr1.address);
    expect(await catchError(async ()=>{ await contentsToken.mint(addr1.address,authorityToken.address,testPhotoId2,asset) })).equal(true);
    expect(await contentsToken.balanceOf(addr1.address)).to.equal(2);
  });

  it("tokenURL confirm", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const after = await contentsToken.tokenURI(1)
    const resJson = JSON.parse(Buffer.from(after.substr('data:application/json;base64,'.length) , "base64").toString());
    expect(resJson.image).to.equal("https://dev.nounsmap.com/p/" + testPhotoId);
  });

  it("AssetAttribute confirm", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    const attr = await contentsToken.getAttributes(1)
    expect(attr.name).to.equal("testContents");
  });

  it("setAdmin", async function () {
    const [owner,addr1] = await ethers.getSigners();    
    expect(await catchError(async ()=>{ await  contentsToken.connect(addr1).setWeb2("https://hoge.com"); })).equal(true);
    await contentsToken.setAdmin(addr1.address);
    await contentsToken.connect(addr1).setWeb2("https://hoge.com");
    const url = await contentsToken.web2Url();
    expect(url).to.equal("https://hoge.com");
  });

});

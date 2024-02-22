const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Document", function () {
  let Document;
  let hardhatDocument;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    Document = await ethers.getContractFactory("Document");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    hardhatDocument = await Document.deploy("https://example.com", 10);
    await hardhatDocument.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await hardhatDocument.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await hardhatDocument.balanceOf(owner.address, 0);
      expect(await hardhatDocument.totalSupply(0)).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should create a new document", async function () {
      await hardhatDocument.connect(addr1).createDoc("Test Document", "Test Hash", "Test Description");
      expect(await hardhatDocument.totalDocs()).to.equal(1);
    });

    it("Should return the correct document", async function () {
      await hardhatDocument.connect(addr1).createDoc("Test Document", "Test Hash", "Test Description");
      const doc = await hardhatDocument.viewToken(0);
      expect(doc.name).to.equal("Test Document");
      expect(doc.docHash).to.equal("Test Hash");
      expect(doc.description).to.equal("Test Description");
    });
  });
});
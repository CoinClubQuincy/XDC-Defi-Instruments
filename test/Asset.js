const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Asset", function () {
  let Asset, asset, owner, addr1, addr2;

  beforeEach(async function () {
    Asset = await ethers.getContractFactory("Asset");
    [owner, addr1, addr2, _] = await ethers.getSigners();
    asset = await Asset.deploy("https://thisissomeMetaData/{id}.json");
    await asset.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await asset.balanceOf(owner.address, 0)).to.equal(1);
    });

    it("Should reject empty URI", async function () {
      const AssetEmpty = await ethers.getContractFactory("Asset");
      await expect(AssetEmpty.deploy("")).to.be.revertedWith("URI cannot be empty");
    });
  });

  describe("Transactions", function () {
    it("Should create new token", async function () {
      await asset.AddToken("Token1", "Attribute1", "Attribute2", "AssetType1");
      const token = await asset.viewToken(0);
      expect(token.name).to.equal("Token1");
      expect(token.description).to.equal("Attribute1");
      expect(token.image).to.equal("Attribute2");
      expect(token.assetType).to.equal("AssetType1");
    });

    it("Should move asset", async function () {
      await asset.AddToken("Token1", "Attribute1", "Attribute2", "AssetType1");
      await asset.moveAsset(0, owner.address, addr1.address, 1);
      expect(await asset.balanceOf(addr1.address, 0)).to.equal(1);
    });

    it("Should destroy asset", async function () {
      await asset.AddToken("Token1", "Attribute1", "Attribute2", "AssetType1");
      await asset.destroyAsset(0, owner.address);
      expect(await asset.balanceOf(owner.address, 0)).to.equal(0);
    });
  });
});
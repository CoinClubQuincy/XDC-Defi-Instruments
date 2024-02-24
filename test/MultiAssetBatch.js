const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiAssetBatch", function () {
  let MultiAssetBatch, ERC1155Mock;
  let multiAssetBatch, erc1155Mock;
  let owner, handler, addrs;

  beforeEach(async function () {
    MultiAssetBatch = await ethers.getContractFactory("MultiAssetBatch");
    ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");
    [owner, handler, ...addrs] = await ethers.getSigners();

    erc1155Mock = await ERC1155Mock.deploy("https://example.com");
    await erc1155Mock.deployed();

    multiAssetBatch = await MultiAssetBatch.deploy(1, "https://example.com", "Batch1", 10);
    await multiAssetBatch.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right handler token, batch name, and max batch size", async function () {
      expect(await multiAssetBatch.handlerToken()).to.equal(uint(keccak256(abi.encodePacked("https://example.com"))));
      expect(await multiAssetBatch.batchName()).to.equal("Batch1");
      expect(await multiAssetBatch.maxBatchSize()).to.equal(10);
    });
  });

  describe("Transactions", function () {
    it("Should add assets", async function () {
      await erc1155Mock.connect(handler).mint(handler.address, 1, 100, []);
      await multiAssetBatch.connect(handler).addAssets(erc1155Mock.address, "Asset1", [1], [100]);
      const asset = await multiAssetBatch.viewAssets(0);
      expect(asset.assetContract).to.equal(erc1155Mock.address);
      expect(asset.assetName).to.equal("Asset1");
      expect(asset.amount[0]).to.equal(100);
      expect(asset.assetID[0]).to.equal(1);
      expect(asset.count).to.equal(0);
      expect(asset.exist).to.equal(true);
    });

    it("Should redeem assets", async function () {
      await erc1155Mock.connect(handler).mint(handler.address, 1, 100, []);
      await multiAssetBatch.connect(handler).addAssets(erc1155Mock.address, "Asset1", [1], [100]);
      await multiAssetBatch.connect(handler).redeemAssets();
      expect(await erc1155Mock.balanceOf(handler.address, 1)).to.equal(100);
    });
  });
});
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Future", function () {
  let ASSET, Future;
  let asset, future;
  let owner, handler, buyer, addrs;

  beforeEach(async function () {
    ASSET = await ethers.getContractFactory("ASSET");
    Future = await ethers.getContractFactory("Future");
    [owner, handler, buyer, addrs] = await ethers.getSigners();

    asset = await ASSET.deploy();
    await asset.deployed();

    future = await Future.deploy([asset.address], [1], 10, 1, "https://example.com", 86400);
    await future.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right asset token address and tokens", async function () {
      expect(await future.AssetTokenAddress()).to.equal(asset.address);
      expect(await future.Tokens(0)).to.equal(1);
    });
  });

  describe("Transactions", function () {
    it("Should list the sale", async function () {
      await future.connect(handler).listSale(1633027200, ethers.utils.parseEther("1"));
      expect(await future.realeaseDate()).to.equal(1633027200);
      expect(await future.price()).to.equal(ethers.utils.parseEther("1"));
    });

    it("Should initiate the contract", async function () {
      await future.connect(buyer).initiateContract({ value: ethers.utils.parseEther("1.1") });
      expect(await future.balanceOf(buyer.address, 0)).to.equal(1);
      expect(await future.contractSold()).to.equal(true);
    });

    it("Should buy the asset", async function () {
      await future.connect(buyer).BuyAsset({ value: ethers.utils.parseEther("1") });
      expect(await asset.balanceOf(buyer.address, 1)).to.equal(1);
      expect(await future.CompletionStatus()).to.equal(true);
    });

    it("Should redeem the deposit", async function () {
      await future.connect(handler).redeemDeposit();
      expect(await ethers.provider.getBalance(handler.address)).to.equal(ethers.utils.parseEther("1.1"));
    });
  });
});
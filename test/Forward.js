const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Forward", function () {
  let ASSET, Forward;
  let asset, forward;
  let owner, buyer, addr3, ...addrs;

  beforeEach(async function () {
    ASSET = await ethers.getContractFactory("ASSET");
    Forward = await ethers.getContractFactory("Forward");
    [owner, buyer, addr3, ...addrs] = await ethers.getSigners();

    asset = await ASSET.deploy();
    await asset.deployed();

    forward = await Forward.deploy("https://example.com");
    await forward.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await forward.owner()).to.equal(owner.address);
    });
  });

  describe("Transactions", function () {
    it("Should deploy assets", async function () {
      await forward.deployAssets(asset.address, 100, Date.now() + 10000, ethers.utils.parseEther("1"));
      expect(await forward.AssetTokenAddress()).to.equal(asset.address);
      expect(await forward.Tokens()).to.equal(100);
      expect(await forward.realeaseDate()).to.be.gt(Date.now());
      expect(await forward.price()).to.equal(ethers.utils.parseEther("1"));
    });

    it("Should buy forward token", async function () {
      await forward.deployAssets(asset.address, 100, Date.now() + 10000, ethers.utils.parseEther("1"));
      await forward.connect(buyer).buyForwardsToken({ value: ethers.utils.parseEther("1") });
      expect(await forward.balanceOf(buyer.address, 0)).to.equal(1);
    });

    it("Should redeem forward", async function () {
      await forward.deployAssets(asset.address, 100, Date.now() + 10000, ethers.utils.parseEther("1"));
      await forward.connect(buyer).buyForwardsToken({ value: ethers.utils.parseEther("1") });
      await ethers.provider.send("evm_increaseTime", [10000]);  // Increase time to pass the release date
      await ethers.provider.send("evm_mine");  // Mine the next block
      await forward.connect(buyer).redeemForward();
      expect(await asset.balanceOf(buyer.address, 100)).to.equal(1);
    });

    it("Should redeem contract value", async function () {
      await forward.deployAssets(asset.address, 100, Date.now() + 10000, ethers.utils.parseEther("1"));
      await forward.connect(buyer).buyForwardsToken({ value: ethers.utils.parseEther("1") });
      await forward.redeemContractValue();
      expect(await ethers.provider.getBalance(forward.address)).to.equal(0);
    });
  });
});
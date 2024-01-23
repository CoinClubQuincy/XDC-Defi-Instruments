const { 
  time, 
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Asset", function () {

    async function AssetContractLoad() {
      const [owner, otherAccount] = await ethers.getSigners();
      const URI = "{ Test URI }"
      const Asset = await ethers.getContractFactory("Asset");
      const asset = await Asset.deploy(URI);

      return { asset, owner, otherAccount };
    }
  
    describe("Deploy Contract", async function () {
      const { asset } = await loadFixture(AssetContractLoad);
      const totalCoins = await asset.totalCoins();

      expect(totalCoins).to.equal(0);
    });

    it("viewToken", async function () {
      const { asset } = await loadFixture(AssetContractLoad);

      expect(asset.totalCoins()).equal(0);
    });
  });
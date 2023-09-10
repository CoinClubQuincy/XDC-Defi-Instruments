const { time, loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
  
  before("Asset", function () {

    async function init() {

    }
  
    describe("Contract Unit Test", function () {
      it("AddToken", async function () {
        const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.unlockTime()).to.equal(unlockTime);
      });
  
      it("viewToken", async function () {
        const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.owner()).to.equal(owner.address);
      });
      it("moveAsset", async function () {
        const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.owner()).to.equal(owner.address);
      });
      it("destroyAsset", async function () {
        const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.owner()).to.equal(owner.address);
      });
      it("Variables", async function () {
        const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.unlockTime()).to.equal(unlockTime);
      });
    });

    describe("Contract Functional Test", function () {
      it("4", async function () {
        const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.unlockTime()).to.equal(unlockTime);
      });
  
      it("FuncB", async function () {
        const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  
        expect(await lock.owner()).to.equal(owner.address);
      });
    });
})
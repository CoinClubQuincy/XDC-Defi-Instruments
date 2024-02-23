const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Contract", function () {
  let Contract, ContractDeployer;
  let contract, contractDeployer;
  let owner, partyA, partyB, witnessA, witnessB, ...addrs;

  beforeEach(async function () {
    Contract = await ethers.getContractFactory("Contract");
    ContractDeployer = await ethers.getContractFactory("ContractDeployer");
    [owner, partyA, partyB, witnessA, witnessB, ...addrs] = await ethers.getSigners();

    contractDeployer = await ContractDeployer.deploy();
    await contractDeployer.deployed();

    const contractAddress = await contractDeployer.deployContract("hash", "name", "https://example.com");
    contract = await Contract.attach(contractAddress);
  });

  describe("Deployment", function () {
    it("Should set the right document hash and name", async function () {
      expect(await contract.DocumentHash()).to.equal("hash");
      expect(await contract.name()).to.equal("name");
    });
  });

  describe("Transactions", function () {
    it("Should make a counter proposal A", async function () {
      await contract.connect(partyA).counter_proposal_A("newHash");
      expect(await contract.DocumentHash()).to.equal("newHash");
      expect(await contract.total_Counter_Proposals()).to.equal(1);
    });

    it("Should make a counter proposal B", async function () {
      await contract.connect(partyB).counter_proposal_B("newHash");
      expect(await contract.DocumentHash()).to.equal("newHash");
      expect(await contract.total_Counter_Proposals()).to.equal(1);
    });

    it("Should sign the proposal", async function () {
      await contract.connect(partyA).sign_proposal();
      expect(await contract.PartyASignature()).to.equal(partyA.address);

      await contract.connect(partyB).sign_proposal();
      expect(await contract.PartyBSignature()).to.equal(partyB.address);

      await contract.connect(witnessA).sign_proposal();
      expect(await contract.WitnessASignature()).to.equal(witnessA.address);

      await contract.connect(witnessB).sign_proposal();
      expect(await contract.WitnessBSignature()).to.equal(witnessB.address);

      expect(await contract.contractComplete()).to.equal(true);
    });
  });
});
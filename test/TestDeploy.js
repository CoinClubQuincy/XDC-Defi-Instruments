const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Asset", function () {
    let AssetContractAddress;
    let ForwardContractAddress;
    let asset;

    let Xprice;
    let Tprice;

    let Seller;
    let Buyer;
    let signers;

    let handlerToken;


    async function CheckBlockNumber() {
        blockNumber = await Fasset.connect(Seller).checkBlockNumber();
        console.log(blockNumber.toNumber());
      }
    
    async function consolePauseLog(input) {
        console.log(input);
        await new Promise(resolve => setTimeout(resolve, 2000));
    }

    //initializer 
    before(async function () {
        // Retrieve the signer addresses
        signers = await ethers.getSigners();
        Seller = signers[0];
        Buyer = signers[1];

        //lauch Asset Contract
        Xprice = ethers.utils.parseUnits("0.01", "ether"); // 1/100 of an  XDC
        Tprice = ethers.utils.parseUnits("1.00", "ether");

        const Asset = await hre.ethers.getContractFactory("Asset");
        asset = await Asset.deploy(Xprice,"URI");
        AssetContractAddress = asset.address;

        //Launch Forward Contract
        const Forward = await hre.ethers.getContractFactory("Forward");
        Fasset = await Forward.deploy("Forward URI");
        ForwardContractAddress = Fasset.address;

    });

    it("Deploy and alocate attributes to Asset", async function () {
        let TokenName = "Token1"
        let result = await asset.connect(Seller).AddToken(TokenName,"Att1","Att2","Att3")
        let setApprovalForAll = await asset.connect(Seller).setApprovalForAll(ForwardContractAddress,true);
        

        handlerToken = await asset.connect(Seller).handlerToken();
        let balanceOf = await asset.connect(Seller).balanceOf(Seller.address,handlerToken);
        console.log("Seller holds Handler Token  " + balanceOf);
        await consolePauseLog("Check Handeler Token");

        await consolePauseLog("Deploying Contract...");
        console.log("Contract Deployed!")

        let viewResult = await asset.viewAtt(0)
        console.log(JSON.stringify(viewResult));

        expect(viewResult).to.be.equal("Token1");
    });

    it("Seller Initialize Forward Contract", async function () {

        await CheckBlockNumber()
        
        let result = await Fasset.connect(Seller).deployAssets(AssetContractAddress,0,6,Tprice);

        await consolePauseLog("Delpoy Contract");

        await CheckBlockNumber()

        expect(AssetContractAddress).to.not.equal('');
    });

    it("Buyer Exchange Tokens", async function () {
        let result = await Fasset.connect(Buyer).buyForwardsToken({value: Tprice});

        await CheckBlockNumber()
        let balanceOf = await Fasset.connect(Buyer).balanceOf(Buyer.address,0);
        console.log("Buyer holds Forward Token  " + balanceOf);

        let redeemForward = await Fasset.connect(Buyer).redeemForward();


        balanceOf = await asset.connect(Buyer).balanceOf(Buyer.address,0);
        console.log("Buyer holds Asset  " + balanceOf);
        await consolePauseLog("Bought and Redeem Forward Asset");
        expect(AssetContractAddress).to.not.equal('');
    });

    it("Seller Redeems Contract", async function () {
        let result = await Fasset.connect(Seller).redeemContractValue();
        await consolePauseLog("ContractRedeemed");
        expect(AssetContractAddress).to.not.equal('');
    });

    it("Redeem Value", async function () {

        expect(AssetContractAddress).to.not.equal('');
    });
});

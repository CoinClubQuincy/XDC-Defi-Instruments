
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Smart contract
contract ASSET is ERC1155 {
        constructor() ERC1155("https://thisissomeMetaData/{id}.json") {
    }
} 
//Smart contract
contract Future is ERC1155 {
    uint256 public constant futureToken = 0;
    uint256 public constant handelerToken = 0;
    uint public realeaseDate = 0;
    uint public price = 0;
    bool public contractSold = false;
    address public AssetTokenAddress;
    ASSET public Asset;
    uint[] public AssetTokens;
    address[] public TokenList;
    uint[] public TokenAmmounts;
    uint[] public Tokens;
    uint public Deposit; // 100 = 1% | 10 = 10% | 4 = 25% | 2 = 50% 
    uint public fee; // 1 = 0.1% 10 basis points
    uint public currentFee;

    constructor(address[] memory _AssetTokenAddress,uint[] memory _Tokens,uint _divisable, uint _fee) ERC1155("https://thisissomeMetaData/{id}.json") {
        AssetTokenAddress = _AssetTokenAddress[0];
        Tokens = _Tokens;
        Deposit = _divisable;
        fee = _fee;
        currentFee = (price/1000) * _fee;
        Asset = ASSET(AssetTokenAddress);
        for (uint i; i <= _Tokens.length;i++) {
            TokenList.push(address(this));
            TokenAmmounts.push(1);
        }
        require(Asset.balanceOfBatch(TokenList, _Tokens).length == _Tokens.length, "Contract must hold tokens");
        _mint(msg.sender,handelerToken,1, "");
    }
    //only the holder of the handlerToken can access functions with this modifier
    modifier Handeler{
        require(balanceOf(msg.sender,handelerToken) == 1);
        _;
    }
    //only the holder of the FutureToken can access functions with this modifier
    modifier FutureToken{
        require(balanceOf(msg.sender,futureToken) == 1);
        require(block.timestamp <= realeaseDate);
        _;
    }
    // if token has been bought user cant execute the fuction with this modifire
    modifier bought{
        require(contractSold == false);
        _;
    }
    // Crreate func to list token price and drop commodities token in futures contract | as well as collatoral limit
    function listSale(uint _realeaseDate, uint _price) private Handeler bought returns(bool){
        realeaseDate = _realeaseDate;
        price = _price;
        return true;
    }
    // create sales function to but contract 
    function initiateContract()public payable bought returns(bool){
        require(msg.value>=Deposit+currentFee,"funds note enough to purchace contract");
        if(msg.value>price){
            payable(msg.sender).transfer(msg.value - price);
        }
        _mint(msg.sender,futureToken,1, "");
        contractSold = true;
        return true;
    }
    // token holder can redeem contract once time has elaps
    function BuyAsset()public payable FutureToken returns(bool,string memory){
        require(msg.value == price - Deposit,"not enough funds");
        Asset.safeBatchTransferFrom(address(this), msg.sender, Tokens, TokenAmmounts, "0x0");
        return (true,"Future Contract Redeemed");
    }
    function redeemDeposit()public payable Handeler returns(bool,string memory){
        require(contractSold = true,"contract not sold");
        payable(msg.sender).transfer(Deposit + currentFee);
        return (true,"Future Contract Redeemed");
    }
    //ERC1155Received fuctions
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
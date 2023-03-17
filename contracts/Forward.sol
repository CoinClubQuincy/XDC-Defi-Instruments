// There are four key differences between forward vs future contracts: 
// forwards are non-transferable,customizable, and illiquid, 
// as well as exposed to counterparty default risk.
//  Details like quantity,expiration date, and price can be adjusted as agreed upon in the contract between the two parties privately.

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ASSET is ERC1155 {
        constructor() ERC1155("https://thisissomeMetaData/{id}.json") {
    }
}

//Smart contract
contract Forward is ERC1155 {
    uint256 public constant forwardToken = 0;
    uint256 public constant handelerToken = 0;
    uint public realeaseDate = 0;
    uint public price = 0;
    bool public contractSold = false;
    address public CommodityTokenAddress;
    ASSET public Asset;
    uint[] public CommodityTokens;
    address[] public TokenList;
    uint[] public TokenAmmounts;

    constructor(address[] memory _CommodityTokenAddress,uint[] memory _Tokens) ERC1155("https://thisissomeMetaData/{id}.json") {
        CommodityTokenAddress = _CommodityTokenAddress[0];
        Asset = ASSET(CommodityTokenAddress);
        //CommodityTokenAddress.safeTransferFrom(address(this),msg.sender,shareToken, 1, "");
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
    //only the holder of the ForwardToken can access functions with this modifier
    modifier ForwardToken{
        require(balanceOf(msg.sender,forwardToken) == 1);
        require(block.timestamp <= realeaseDate);
        _;
    }
    // if token has been bought user cant execute the fuction with this modifire
    modifier bought{
        require(contractSold == false);
        _;
    }
    // Crreate func to list token price and drop commodities token in forwards contract | as well as collatoral limit
    function listSale(uint _realeaseDate, uint _price) public Handeler bought returns(bool){
        realeaseDate = _realeaseDate;
        price = _price;
        return true;
    }
    // create sales function to but contract 
    function buyForwardsToken()public payable  bought returns(bool){
        _mint(msg.sender,forwardToken,1, "");
        contractSold = true;
        return true;
    }
    // token holder can redeem contract once time has elaps
    function redeemForward()public ForwardToken returns(bool,string memory){
        Asset.safeTransferFrom(address(this), msg.sender, TokenList, TokenAmmounts, "");
        return (true,"Forward Contract Redeemed");
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
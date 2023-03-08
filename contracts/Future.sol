
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Smart contract
contract Future is ERC1155 {
    uint256 public constant futureToken = 0;
    uint256 public constant handelerToken = 0;
    uint public realeaseDate = 0;
    uint public price = 0;
    bool public contractSold = false;

    constructor() ERC1155("https://thisissomeMetaData/{id}.json") {
        _mint(msg.sender,handelerToken,1, "");
    }
    //only the holder of the handlerToken can access functions with this modifier
    modifier Handeler{
        require(balanceOf(msg.sender,handelerToken) == 1);
        _;
    }
    //only the holder of the ForwardToken can access functions with this modifier
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
    // Crreate func to list token price and drop commodities token in forwards contract | as well as collatoral limit
    function listSale(uint _realeaseDate, uint _price) public Handeler bought returns(bool){
        realeaseDate = _realeaseDate;
        price = _price;
        return true;
    }
    // create sales function to but contract 
    function buyFutureToken()public payable  bought returns(bool){
        _mint(msg.sender,futureToken,1, "");
        contractSold = true;
        return true;
    }
    // token holder can redeem contract once time has elaps
    function redeemFuture()public FutureToken returns(bool){

        return true;
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
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

//This contract is a representation of how a simple asset that can 
//be issued on the XDC Network as a derivative of a tangable asset
//:Stocks | Commodities | Tresuries 


//Example URI
// {
//     "name": "{id}",
//     "description": "https://hostedSite/description/{id}",
//     "image": "https://hostedSite/{id}",
//     "Broker": "QTrade" 
// }

contract Asset is ERC1155 {
    uint public totalCoins = 0;     //toal tokens
    uint public handlerToken;       
    
    //initializer Execute some initial code as contract is launched
    constructor(string memory _URI) ERC1155(_URI) {
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,1, "");
    }
    //The Handler function allows the holder of the handler token to allows the owner of the contract create more assets 
    // As well as allows only the handler to redeem value from the contract
    modifier handler(){
        require(balanceOf(msg.sender,handlerToken) == 1, "user does not hold handlerToken");
        _;
    }

    //Store Asset details within contract  
    mapping(uint => Tokens) public tokens;
    struct Tokens{
        string name;
        string description;
        string image;
        string assetType;
    }

    //This function allows you to add or create new tokens and log their data into the smart contract 
    function AddToken(string memory name, string memory att1, string memory att2 ,string memory att3,string memory assetType)public handler returns(bool){
        _mint(msg.sender,totalCoins,1, "");
        tokens[totalCoins] = Tokens(name,att1,att2,assetType);
        totalCoins++;
        return true;
    }

    //view token name and price of token to gauge what asset is corelated to the index nuber acociatyed with the asset
    function viewToken(uint Token)public view  returns(string memory, string memory, string memory,string memory) {
        return (tokens[Token].name, tokens[Token].description, tokens[Token].image, tokens[Token].assetType);
    }
    //if the broker for any reason need to move the asset from an abandond account
    //they can use the move Asset function 
    function moveAsset(uint Token,address _userA,address _userB)public returns(bool){
        require(balanceOf(_userA, Token) >= 1, "Insufficient balance");
         _burn(_userA, Token, 1);
        _mint(_userB,Token,1, "");
        return true;
    }
    function destroyAsset(uint Token,address _userA)public returns(bool){
        require(balanceOf(_userA, Token) >= 1, "Insufficient balance");
        _burn(_userA, Token, 1);
        return true;
    }
}
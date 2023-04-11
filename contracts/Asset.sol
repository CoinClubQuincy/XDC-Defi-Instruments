// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Smart contract
contract Asset is ERC1155 {
    //Token
    uint256 public constant Item = 0;
    //toal tokens
    uint public totalCoins = 0;
    uint public handlerToken;
    //execution price
    uint public XPrice; // 1XDC
    //Execute some code when contract is launched
    constructor(uint _XPrice,string memory _URI) ERC1155(_URI) {
        XPrice = _XPrice;
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,1, "");
    }
    //if user doesnt have enough they cant execute function
    modifier price(){
        require(msg.value >= XPrice, "Not enough Funds");
        refund();
        _;
    }
    modifier handler(){
        require(balanceOf(msg.sender,handlerToken) == 1, "user does not hold handlerToken");
        _;
    }
    //map token number to struct and mappping
    mapping(uint => Tokens) public tokens;
    struct Tokens{
        string name;
        string attribute1;
        string attribute2;
        string attribute3;
    }
    //function to add or create a token
    function AddToken(string memory name, string memory att1, string memory att2 ,string memory att3)public handler returns(bool){
        //creates the token
        _mint(msg.sender,totalCoins,1, "");
        //asigns attributes
        tokens[totalCoins] = Tokens(name,att1,att2,att3);
        //keeps track of ammount of tokens
        totalCoins++;
        return true;
    }
    //view token name data for free
    function viewAtt(uint Token)public view returns(string memory){
        return (tokens[Token].name);
    }
    //pay to view all token data
    function payAtt(uint Token) public payable price returns(string memory, string memory, string memory, string memory) {
        //Proof of concept most data  would be a calulation of consolidation of data both from the natic contract but also seperate smart contracts
        return (tokens[Token].name, tokens[Token].attribute1, tokens[Token].attribute2, tokens[Token].attribute3);
    }
    //handler Can redeem funds from contract
    function redeemContractValue()public handler returns(bool){
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
    //refund user if they overpay
    function refund()internal {
        if(msg.value>XPrice){
            payable(msg.sender).transfer(msg.value - XPrice);
        }
    }
}
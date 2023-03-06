// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Smart contract
contract Commodity is ERC1155 {
    //Token
    uint256 public constant Item = 0;
    //toal tokens
    uint totalCoins = 0;
    //execution price
    uint XPrice = 10000000000000000000; // 1XDC
    //Execute some code when contract is launched
    constructor() ERC1155("https://this is soimeMetaData/{id}.json") {}
    //if user doesnt have enough they cant execute function
    modifier price(){
        require(msg.value >= XPrice);
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
    function AddToken(string memory name, string memory att1, string memory att2 ,string memory att3)public returns(bool){
        //creates the token
        _mint(msg.sender,totalCoins,1, "");
        //asigns attributes
        tokens[totalCoins] = Tokens(name,att1,att2,att3);
        //keeps track of ammount of tokens
        totalCoins++;
        return true;
    }
    //view data for free
    function viewAtt(uint Token)public view returns(string memory){
        return (tokens[Token].name);
    }
    //pay to view data
    function payAtt(uint Token)public payable price returns(string memory,string memory,string memory,string memory){
        return (tokens[Token].name,tokens[Token].attribute1,tokens[Token].attribute2,tokens[Token].attribute3);
    }
}
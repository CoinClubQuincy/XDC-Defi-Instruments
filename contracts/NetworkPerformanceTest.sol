// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Smart contract
contract GenerateRandomStats {

    bool public contractComplete = false;
    //Generates 1000 random numbers that are associated and mapped 
    constructor(uint _entrapy) {
        for(uint token =0; token <=1000;token++) {
            //_mint(msg.sender,token,1, "");
            uint stats = randomStats(_entrapy+token,100);
            data[token] = Data(stats,token,"random Token");
        }
    }
    //data mapping stats to struct
    mapping(uint => Data) data;
    struct Data{
        uint Name;
        uint Numb;
        string Type;
    }
    //generates a number thats "random enough"
    function randomStats(uint _entrapy, uint _multiplier) public view returns(uint){ 
        uint256 seed = uint256(keccak256(abi.encodePacked( block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number + _entrapy)));
        
        return (seed - ((seed / _multiplier) * _multiplier));
    }
    //Reads data from mapped struct
    function readToken(uint _token)public view returns(uint,uint,string memory){
        return (data[_token].Name,data[_token].Numb,data[_token].Type);
    }
}
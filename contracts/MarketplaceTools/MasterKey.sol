// // SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.8.2 <0.9.0;
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// /// @title Master Key Contract
// /// @author R Quincy Jones
// /// @notice This is a contract that is meant to manage keys for other apps managed by administrators
// /// @dev Manages and create keys

// contract Admin is ERC1155{
//     uint public adminKey;  
//     constructor(string memory _URI,uint _totalKeys) ERC1155(_URI) {
//         adminKey = uint(keccak256(abi.encodePacked(_URI)));
//         _mint(msg.sender,adminKey,_totalKeys, "");
//     }
// }


// contract MasterKey is ERC1155 {
//     uint public totalMasterKeys = 0;  
//     uint public handlerKey;  
//     uint public keysSigned = 0;
//     uint public totalKeys;
//     uint public currentVote = 0;
//     Type public types;

//     constructor(string memory _URI,uint _totalKeys) ERC1155(_URI) {
//         totalKeys = _totalKeys;
//         handlerKey = uint(keccak256(abi.encodePacked(_URI)));
//         _mint(msg.sender,handlerKey,_totalKeys, "");
//     }

//     modifier Handler(){
//         require(balanceOf(msg.sender,handlerKey) >= 1, "user does not hold handlerToken");
//         _;
//     }

//     modifier Master(){
//         require(votes[currentVote].timeStamp > block.number + 90,"Vote has Expired");
//         require(keyCount[currentVote].voteCount == totalKeys, "Vote must be passed");
//         _;
//     }

//     enum Type{
//         current,
//         pending,
//         complete,
//         expired
//     }

//     mapping(uint => KeyLedger) keyCount;
//     mapping(address => KeyLedger) keyVerify;
//     struct KeyLedger{
//         uint voteNumb;
//         uint voteCount;
//         bool exist;
//     }

//     mapping(uint => Vote) votes;
//     struct Vote{
//         uint timeStamp;
//         Type status;
//         uint vote;
//         bool exist;
//     }

//     mapping(uint => Register) register;
//     struct Register{
//         address user;
//         uint key;
//         bool exist;
//     }

//     //withdraw any Tokens that give admin permissions
//     function withdrawMasterToken() public Master returns(bool){}

//     function voteNewKey() public Handler returns(bool){}

//     //create new Master keys
//     function createMasterKeys(address _user) public Master returns(bool){
//         _mint(_user,handlerKey,1, "");
//         return true;
//     }

//     //destroy masterKey
//     function destroyMasterKeys(address _user) public Master returns(bool){
//         _burn(_user, handlerKey, 1);
//         return true;
//     }

//     function addNewKeys() public Master returns(bool){}

//     function createNewKey(address _user) public Master returns(bool){}
    
//     function destroyNewKey(address _user) public Master returns(bool){}

//     //ERC1155Received fuctions
//     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155Received.selector;
//     }
//     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155BatchReceived.selector;
//     }
//     function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC721Received.selector;
//     }

//     fallback() external payable {}
//     receive() external payable {} 
// }
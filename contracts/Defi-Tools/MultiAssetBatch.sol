//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Multi Asset Batch Contract
/// @author Quincy J
/// @notice This contract is meant to allow a multitude of different assets from different contracts to be referenced by a single token
/// @dev This contract is built to allow for more complex contracts to only have to manage  a single token rather than a complex multitude of different tokens

contract MultiAssetBatch is ERC1155{
    uint public handlerToken;
    string public batchName;
    uint public tokenIDNumber = 0;
    uint public maxBatchSize; //50-100 recomended

    constructor(uint _totalHandlers,string memory _URI,string memory _batchName,uint _maxBatchSize) ERC1155(_URI) {
        require(_totalHandlers > 0, "Total handlers must be greater than 0");
        require(bytes(_URI).length > 0, "URI cannot be empty");
        require(bytes(_batchName).length > 0, "Batch name cannot be empty");
        require(_maxBatchSize > 0, "Max batch size must be greater than 0");

        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,_totalHandlers, "");
        batchName = _batchName;
        maxBatchSize = _maxBatchSize; 
    }

    mapping(uint => Assets) assetID;
    mapping(address => Assets) assetContract;
    struct Assets{
        address assetContract;
        string assetName;
        uint[] amount;
        uint[] assetID;
        uint count;
        bool exist;
    }

    modifier handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }
    
    function addAssets(address _contract,string memory _assetName,uint[] memory _id,uint[] memory _amount)public handler returns(string memory,bool){
        require(tokenIDNumber <= maxBatchSize,"Contract has hit Max Batch limit");
        require(_contract != address(0), "Contract address cannot be 0");
        require(bytes(_assetName).length > 0, "Asset name cannot be empty");
        require(_id.length > 0, "ID array cannot be empty");
        require(_amount.length > 0, "Amount array cannot be empty");
        require(_id.length == _amount.length ,"Both the token id and the amount arrays must have the same length");
        
        ERC1155 tokenContract = ERC1155(_contract);

        if(assetContract[_contract].exist == false){
            assetContract[_contract] = Assets(_contract,_assetName,_amount,_id,tokenIDNumber,true);
            assetID[tokenIDNumber] = Assets(_contract,_assetName,_amount,_id,tokenIDNumber,true);
            tokenIDNumber++;

            for(uint i =0;i<= _id.length;i++){
                require(tokenContract.balanceOf(msg.sender,_id[i]) >= 1,"user is missing a token");
            }

            tokenContract.safeBatchTransferFrom(msg.sender, address(this), _id, _amount, "");
            return ("new asset added",true);

        }else if(assetContract[_contract].exist == true && _id.length != 0 && _amount.length != 0 && _amount.length == _id.length){
            for(uint256 i = 0; i < _id.length; i++){
                assetContract[_contract].assetID.push(_id[i]);
                assetContract[_contract].amount.push(_amount[i]);

                assetID[assetContract[_contract].count].assetID.push(_id[i]);
                assetID[assetContract[_contract].count].amount.push(_amount[i]);
            }
            tokenContract.safeBatchTransferFrom(msg.sender, address(this), _id, _amount, "");

            return ("Assets Added",true);
        } else {
            return ("asset already exist",false);
        }
    }

    function redeemAssets()public handler returns(bool){
        for(uint i; i <= tokenIDNumber;i++){
            ERC1155 tokenContract = ERC1155(assetID[i].assetContract);
            tokenContract.safeBatchTransferFrom(address(this),msg.sender, assetID[i].assetID, assetID[i].amount, "");
        }
        return true;
    }

    function viewAssets(uint _tokenIDNumber)public  view returns(address,string memory,uint[] memory,uint[] memory,uint,bool){
        return (assetID[_tokenIDNumber].assetContract,assetID[_tokenIDNumber].assetName,assetID[_tokenIDNumber].amount,assetID[_tokenIDNumber].assetID,assetID[_tokenIDNumber].count,assetID[_tokenIDNumber].exist);
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

    fallback() external payable {}
    receive() external payable {} 
}
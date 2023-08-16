//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


abstract contract MultiAssetBatch is ERC1155{
    uint public handlerToken;
    string public batchName;
    uint public assetIDCount = 0;
    uint public maxBatchSize;

    constructor(uint _totalHandlers,string memory _URI,string memory _batchName,uint _maxBatchSize) ERC1155(_URI)   {
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,_totalHandlers, "");
        batchName = _batchName;
        maxBatchSize = _maxBatchSize; //50-100 recomended
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
        require(assetIDCount <= maxBatchSize,"Contract has hit Max Batch limit");
        require(_id.length ==_amount.length ,"both the token id and the ammount arrays must have the same length");
        ERC1155 tokenContract = ERC1155(_contract);
        if(assetContract[_contract].exist == false){
            assetContract[_contract] = Assets(_contract,_assetName,_amount,_id,assetIDCount,true);
            assetID[assetIDCount] = Assets(_contract,_assetName,_amount,_id,assetIDCount,true);
            assetIDCount++;

            for(uint i;i<= _id.length;i++){
                require(tokenContract.balanceOf(msg.sender,_id[i]) >= 1,"user is missing a token");
            }
            
            tokenContract.safeBatchTransferFrom(msg.sender, address(this), _id, _amount, "");
            return ("new asset added",true);
        } else {
            return ("asset already exist",false);
        }
    }

    function redeemAssets()public handler returns(bool){
        for(uint i; i <= assetIDCount;i++){
            ERC1155 tokenContract = ERC1155(assetID[i].assetContract);
            tokenContract.safeBatchTransferFrom(address(this),msg.sender, assetID[i].assetID, assetID[i].amount, "");
        }
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
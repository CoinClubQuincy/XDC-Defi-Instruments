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


/// @title Forwards Contract
/// @author R Quincy Jones
/// @notice This is an automated forwards contract
/// @dev This contract can be used with ERC1150 tokens 

contract Forward is ERC1155 {
    uint256 public constant forwardToken = 0;
    uint256 public handlerToken;
    uint public realeaseDate = 0;
    uint public price = 0;
    bool public contractSold = false;
    address public AssetTokenAddress;
    ASSET public Asset;

    uint public Tokens;
    bool public activated;

    constructor(string memory _URI) ERC1155(_URI) {
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,1, "");
    }
    //only the holder of the handlerToken can access functions with this modifier
    modifier Handler{
        require(balanceOf(msg.sender,handlerToken) == 1,"you are currently not the handeler of this contract");
        _;
    }
    //only the holder of the ForwardToken can access functions with this modifier
    modifier ForwardToken{
        require(balanceOf(msg.sender,forwardToken) == 1,"you currently do not have custody of this contracts token");
        require(block.timestamp >= realeaseDate,"the date of maturity has not passed");
        _;
    }
    // if token has been bought user cant execute the fuction with this modifire
    modifier bought{
        require(contractSold == false,"contract has been sold");
        _;
    }
    modifier activate{
        require(activated == true,"contract has not been activated");
        _;
    }

    function checkBlockNumber()public view returns(uint){
        return block.number;
    }

    // Create func to list token price and drop commodities token in forwards contract
    function deployAssets(address _AssetTokenAddress,uint _Tokens,uint _realeaseDate, uint _price)public Handler returns(bool){
        require(_AssetTokenAddress != address(0), "Invalid asset token address");
        require(_Tokens > 0, "Tokens must be greater than 0");
        require(_realeaseDate > block.timestamp, "Release date must be in the future");
        require(_price > 0, "Price must be greater than 0");
        
        realeaseDate = _realeaseDate;
        price = _price;
        AssetTokenAddress = _AssetTokenAddress;
        Tokens = _Tokens;
        Asset = ASSET(AssetTokenAddress);
        Asset.safeTransferFrom(msg.sender,address(this),_Tokens, 1, "");
        activated = true;
        return true;
    }
    // create sales function to but contract 
    function buyForwardsToken()public payable  bought activate returns(bool){
        require(msg.value>=price,"funds not enough to purchase contract");
        _mint(msg.sender,forwardToken,1, "");
        contractSold = true;
        refund();
        return true;
    }
    // token holder can redeem contract once time has elaps
    function redeemForward()public ForwardToken returns(bool,string memory){
        Asset.safeTransferFrom(address(this), msg.sender, Tokens, 1, "0x0");
        return (true,"Forward Contract Redeemed");
    }
    function redeemContractValue()public Handler returns(bool){
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
    function refund()internal {
        if(msg.value>price){
            payable(msg.sender).transfer(msg.value - price);
        }
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
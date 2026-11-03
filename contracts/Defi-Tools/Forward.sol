// There are four key differences between forward vs future contracts: 
// forwards are non-transferable,customizable, and illiquid, 
// as well as exposed to counterparty default risk.
//  Details like quantity,expiration date, and price can be adjusted as agreed upon in the contract between the two parties privately.

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Forwards Contract
/// @author R Quincy Jones
/// @notice The handler escrows one asset token and sets a price and a date. A buyer pays the full
/// price now, and can collect the asset once the date passes.
/// @dev This contract can be used with ERC1155 tokens. The buyer should check AssetTokenAddress,
/// since the handler chooses which token contract to use

contract Forward is ERC1155, ReentrancyGuard {
    uint256 public constant forwardToken = 0;
    uint256 public handlerToken;
    uint public realeaseDate = 0;
    uint public price = 0;
    bool public contractSold = false;
    address public AssetTokenAddress;
    IERC1155 public Asset;

    uint public Tokens;
    bool public activated;
    bool public redeemed;

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

    // Lists the price and moves the asset into this contract. The handler must approve this contract first
    function deployAssets(address _AssetTokenAddress,uint _Tokens,uint _realeaseDate, uint _price)public Handler bought nonReentrant returns(bool){
        require(activated == false, "contract has already been activated");
        require(_AssetTokenAddress != address(0), "Invalid asset token address");
        require(_realeaseDate > block.timestamp, "Release date must be in the future");
        require(_price > 0, "Price must be greater than 0");
        
        realeaseDate = _realeaseDate;
        price = _price;
        AssetTokenAddress = _AssetTokenAddress;
        Tokens = _Tokens;
        Asset = IERC1155(AssetTokenAddress);
        activated = true;
        Asset.safeTransferFrom(msg.sender,address(this),_Tokens, 1, "");
        return true;
    }
    // Takes the listing down and returns the asset, as long as nobody has bought it
    function cancelListing()public Handler bought activate nonReentrant returns(bool){
        activated = false;
        Asset.safeTransferFrom(address(this), msg.sender, Tokens, 1, "");
        return true;
    }
    // Buys the contract. The buyer names the terms they read, so the listing can't change while the purchase is pending
    function buyForwardsToken(address _expectedToken,uint _expectedTokenId,uint _expectedDate,uint _expectedPrice)public payable  bought activate nonReentrant returns(bool){
        require(_expectedToken == AssetTokenAddress && _expectedTokenId == Tokens && _expectedDate == realeaseDate && _expectedPrice == price,"the terms have changed");
        require(block.timestamp < realeaseDate,"the date of maturity has passed");
        require(msg.value>=price,"funds not enough to purchase contract");
        contractSold = true;
        _mint(msg.sender,forwardToken,1, "");
        refund();
        return true;
    }
    // token holder can redeem contract once time has elaps
    function redeemForward()public ForwardToken nonReentrant returns(bool,string memory){
        require(redeemed == false, "Forward has already been redeemed");
        redeemed = true;
        _burn(msg.sender, forwardToken, 1);
        Asset.safeTransferFrom(address(this), msg.sender, Tokens, 1, "");
        return (true,"Forward Contract Redeemed");
    }
    function redeemContractValue()public Handler nonReentrant returns(bool){
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Payment failed");
        return true;
    }
    function refund()internal {
        if(msg.value>price){
            (bool sent,) = payable(msg.sender).call{value: msg.value - price}("");
            require(sent, "Refund failed");
        }
    }
    // A forward stays with the buyer who agreed to it
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if(from != address(0) && to != address(0)){
            for(uint i = 0; i < ids.length; i++){
                require(ids[i] != forwardToken, "forwards are non-transferable");
            }
        }
    }
    // Accepts only the asset this contract moves in itself, so nothing else can get stuck here
    function onERC1155Received(address _operator, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        require(msg.sender == AssetTokenAddress && _operator == address(this), "this contract does not accept tokens");
        return this.onERC1155Received.selector;
    }
}

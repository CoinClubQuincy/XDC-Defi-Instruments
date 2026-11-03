// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Futures Contract
/// @author R Quincy Jones
/// @notice The handler escrows asset tokens and sets a price and a date. A buyer pays a deposit and
/// a fee for the future token. Whoever holds that token pays the price within the window after the
/// date, gets the deposit back and receives the assets. If nobody pays in time the contract is in
/// default: the handler keeps the deposit and takes the assets back.
/// @dev This contract can be used with ERC1155 tokens. The future token can be transferred

contract Future is ERC1155, ReentrancyGuard {
    uint256 public constant futureToken = 0;
    uint256 public handelerToken;
    uint public realeaseDate = 0;
    uint public price = 0;
    bool public contractSold = false;
    bool public listed = false;
    address public AssetTokenAddress;
    IERC1155 public Asset;
    uint[] public TokenAmmounts;
    uint[] public Tokens;
    uint public divisable; // 100 = 1% | 10 = 10% | 4 = 25% | 2 = 50% 
    uint public Deposit;
    uint public fee; // 1 = 0.1% 10 basis points
    uint public currentFee;
    uint public redemptionTimeLimit; // the total amount of time before contract defaults after maturity in seconds standard 1Day- 1Week
    uint public handlerBalance; // what the handler can collect with redeemDeposit
    bool public CompletionStatus = false;
    bool public defaultSettled = false;

    constructor(address _AssetTokenAddress,uint[] memory _Tokens,uint _divisable, uint _fee, string memory _URI,uint _redemptionTimeLimit) ERC1155(_URI) {
        require(_AssetTokenAddress != address(0), "Invalid asset token address");
        require(_Tokens.length > 0, "Tokens are required");
        require(_divisable > 0, "Deposit divisor must be greater than 0");
        require(_fee <= 1000, "Fee cannot be above 100%");
        require(_redemptionTimeLimit > 0, "Redemption time limit must be greater than 0");

        AssetTokenAddress = _AssetTokenAddress;
        Asset = IERC1155(_AssetTokenAddress);
        Tokens = _Tokens;
        divisable = _divisable;
        fee = _fee;
        redemptionTimeLimit = _redemptionTimeLimit;
        for (uint i; i < _Tokens.length;i++) {
            TokenAmmounts.push(1);
        }
        handelerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handelerToken,1, "");
    }
    //only the holder of the handlerToken can access functions with this modifier
    modifier Handler{
        require(balanceOf(msg.sender,handelerToken) == 1,"you are currently not the handler of this contract");
        _;
    }
    //only the holder of the FutureToken can access functions with this modifier
    modifier FutureToken{
        require(balanceOf(msg.sender,futureToken) == 1,"you currently do not have custody of this contracts token");
        _;
    }
    // if token has been bought user cant execute the fuction with this modifire
    modifier bought{
        require(contractSold == false,"contract has been sold");
        _;
    }
    function returnChange(uint _total)internal{
        if(msg.value>_total){
            (bool sent,) = payable(msg.sender).call{value: msg.value - _total}("");
            require(sent, "Refund failed");
        }
    }
    function inDefault()public view returns(bool) {
        return contractSold && !CompletionStatus && block.timestamp > realeaseDate + redemptionTimeLimit;
    }
    // Sets the terms and, the first time, moves the assets in. The handler must approve this contract first.
    // Terms can change until somebody buys
    function listSale(uint _realeaseDate, uint _price) public Handler bought nonReentrant returns(bool){
        require(_realeaseDate > block.timestamp, "Release date must be in the future");
        require(_price >= divisable, "Price is too low to set a deposit");
        realeaseDate = _realeaseDate;
        price = _price;
        Deposit = _price / divisable;
        currentFee = (_price * fee) / 1000;
        if(listed == false){
            listed = true;
            Asset.safeBatchTransferFrom(msg.sender, address(this), Tokens, TokenAmmounts, "");
        }
        return true;
    }
    // Takes the listing down and returns the assets, as long as nobody has bought it
    function cancelSale() public Handler bought nonReentrant returns(bool){
        require(listed == true, "contract is not listed");
        listed = false;
        Asset.safeBatchTransferFrom(address(this), msg.sender, Tokens, TokenAmmounts, "");
        return true;
    }
    // create sales function to but contract 
    function initiateContract()public payable bought nonReentrant returns(bool){
        require(listed == true, "contract is not listed");
        require(block.timestamp < realeaseDate, "the date of maturity has passed");
        uint total = Deposit + currentFee;
        require(msg.value>=total,"funds note enough to purchace contract");
        contractSold = true;
        handlerBalance += currentFee;
        _mint(msg.sender,futureToken,1, "");
        returnChange(total);
        return true;
    }
    // token holder pays the price within the window, gets the deposit back and receives the assets
    function BuyAsset()public payable FutureToken nonReentrant returns(bool,string memory){
        require(CompletionStatus == false, "Contract is already completed");
        require(block.timestamp >= realeaseDate,"the date of maturity has not passed");
        require(!inDefault(), "Contract in Default");
        require(msg.value >= price,"not enough funds");

        CompletionStatus = true;
        handlerBalance += price;
        _burn(msg.sender, futureToken, 1);
        Asset.safeBatchTransferFrom(address(this), msg.sender, Tokens, TokenAmmounts, "");
        (bool sent,) = payable(msg.sender).call{value: Deposit + msg.value - price}("");
        require(sent, "Payment failed");
        return (true,"Future Contract Redeemed");
    }
    // Pays the handler what it is owed. After a default that includes the deposit, and the assets come back
    function redeemDeposit()public Handler nonReentrant returns(bool,string memory){
        bool settling = inDefault() && !defaultSettled;
        if(settling){
            defaultSettled = true;
            handlerBalance += Deposit;
        }
        uint amount = handlerBalance;
        require(amount > 0, "Nothing to redeem");
        handlerBalance = 0;
        if(settling){
            Asset.safeBatchTransferFrom(address(this), msg.sender, Tokens, TokenAmmounts, "");
        }
        (bool sent,) = payable(msg.sender).call{value: amount}("");
        require(sent, "Payment failed");
        return (true,"Future Contract Redeemed");
    }
    function checkContractStatus()public view returns(string memory) {
        if(CompletionStatus == true){
            return "Contract is Completed";
        } else if(inDefault()){
            return ("Contract is in Default");
        } else {
            return "Contract Currently Pending";
        }
    }
    // Accepts only the assets this contract moves in itself, so nothing else can get stuck here
    function onERC1155BatchReceived(address _operator, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        require(msg.sender == AssetTokenAddress && _operator == address(this), "this contract does not accept tokens");
        return this.onERC1155BatchReceived.selector;
    }
}

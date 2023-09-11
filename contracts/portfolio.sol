//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./marketplace.sol";


/// @title Marketplace Portfolio
/// @author R Qiuincy Jones
/// @notice This is a portfolio contract that allows a single contract to custody assets from the 1155 marketplace
/// @dev this contravct works well with the 1155 marketplace contract

contract portfolioLedger{
    string portfolioTokenURI;   //URI formart for users
    address marketplaceAddress; //address of marketplace Contract

    uint totalAccounts = 0;
    
    constructor(uint _totalHandlers,string memory _URI,string memory _marketplaceName){
        portfolioTokenURI = _URI;
        marketplaceAddress = address(new Marketplace(_totalHandlers,_URI,_marketplaceName));
        totalAccounts++;
    }
    mapping(string => Ledger) ledger;
    mapping(uint => numberLedger) numbLedger;
    struct Ledger{
        string account;
        uint accountNumber;
        address portfolio;
        bool exist;
    }
    struct numberLedger{
        string account;
        address portfolio;  
        bool exist; 
    }
    //Create new User Account
    function createAccount(string memory _account)public returns(string memory,address){
        require(ledger[_account].exist == false, "account already exist");
        address portfolioContractAddress; 
        portfolioContractAddress = address(new Portfolio(portfolioTokenURI,_account,address(this),marketplaceAddress,msg.sender));
        ledger[_account] = Ledger(_account,totalAccounts,portfolioContractAddress,true);
        numbLedger[totalAccounts] = numberLedger(_account,portfolioContractAddress,true);
        totalAccounts++;
        return ("new account created", portfolioContractAddress);
    }
    //check and view new user Account
    function checkAccount(string memory _account,uint accountNumber)public returns(string memory,address,bool){
        if(ledger[_account].exist = true || numbLedger[accountNumber].exist){
            return (ledger[_account].account,ledger[_account].portfolio,ledger[_account].exist);
        }else{
            return ("none",0x0000000000000000000000000000000000000000,false);
        }
    }
    //forward funds from one user name to another
    function forwardFunds(string memory _reciver)external payable returns(bool){
        string memory account_;
        address portfolio_;
        bool exist_;
        (account_, portfolio_, exist_) = checkAccount(_reciver,0);
        require(exist_ == true, "User does not exist");
        payable(portfolio_).transfer(msg.value);
        return true;
    }
}

contract Portfolio is ERC1155{
    uint public handlerToken;
    string public accountName;
    uint marketplaceCount =0;

    Marketplace public marketplace;
    portfolioLedger public DAppLedger;
    address private ledgerPrivate;
    address currentOwner;

    event changedMarketPlace(string _newmarketplace);
    event changedOwner(string _brokerMSG,address _newOwner);

    mapping(address => savedMarketPlaces) savedmarketplace;
    mapping(uint => savedMarketPlaces) marketplaceNumber;
    struct savedMarketPlaces{
        address marketplaceAddress;
        string marketplaceName;
        bool exist;
    }

    constructor(string memory _URI,string memory _name,address _DAppLedger,address _marketplace,address user) ERC1155(_URI) {
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(user,handlerToken,1, "");

        accountName = _name;
        ledgerPrivate = _DAppLedger;
        DAppLedger = portfolioLedger(_DAppLedger);
        marketplace = Marketplace(_marketplace);
        
        logNewMarketPlace(address(_marketplace));
        
        currentOwner = user;
    }
    modifier broker{
        require(marketplace.balanceOf(msg.sender,marketplace.handlerToken()) >= 1, "broker does not hold handler token");
        _;
    }
    modifier handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }
    function resetOwner(address _newOwner) public broker returns(address){
           _mint(_newOwner,handlerToken,1, "");
           _burn(currentOwner,handlerToken,1);
           currentOwner = _newOwner;

           emit changedOwner("The registerd broker has chaged the owner of this contract",_newOwner);
           return _newOwner;
    }
    function logNewMarketPlace(address _marketplace) internal returns(bool){
            require(savedmarketplace[_marketplace].exist == false, "Markeplace already exist");
            savedmarketplace[_marketplace] = savedMarketPlaces(_marketplace,marketplace.marketplaceName(),true);
            marketplaceNumber[marketplaceCount] = savedMarketPlaces(_marketplace,marketplace.marketplaceName(),true);
            marketplaceCount++;
            return true;
    }
    function saveMarketplace(address _marketplace)public handler returns(bool){
        logNewMarketPlace(_marketplace);
        return true;
    }

    function deleteMarketplace(uint _marketplaceIndex)public handler returns(bool){
        require(savedmarketplace[marketplaceNumber[_marketplaceIndex].marketplaceAddress].exist == false, "Markeplace already exist");
        savedmarketplace[marketplaceNumber[_marketplaceIndex].marketplaceAddress] = savedMarketPlaces(0x0000000000000000000000000000000000000000,"removed",false);
        marketplaceNumber[_marketplaceIndex] = savedMarketPlaces(0x0000000000000000000000000000000000000000,"removed",false);
        marketplaceCount--;
        return true;
    }

    function viewSavedMarketPlaces(uint _marketplaceIndex)public view handler returns(address,string memory,uint){
        return (marketplaceNumber[_marketplaceIndex].marketplaceAddress,marketplaceNumber[_marketplaceIndex].marketplaceName,_marketplaceIndex);
    }

    function changeMarketplace(Marketplace _marketplace) public handler returns(Marketplace){
        marketplace = _marketplace;
        emit changedMarketPlace("Marketplace has been changed");

        if(savedmarketplace[address(_marketplace)].exist != true){
            logNewMarketPlace(address(_marketplace));
        }

        return marketplace;
    }
    function sendFunds(string memory _reciver)public payable handler returns(bool){
        bool success = DAppLedger.forwardFunds{value: msg.value}(_reciver);
        require(success, "Failed to forward funds.");
        return success;
    }

    function createList(address _token,uint256 _tokenId,uint256 _amountOfToken,uint256 _deadline,uint256 _price) public handler returns(bool){
        marketplace.createList(_token,_tokenId,_amountOfToken,_deadline,_price);
        return true;
    }

    function buyListToken(uint _sellId) public payable handler returns(bool){
        marketplace.buyListToken{value: msg.value}(_sellId);
        return true;
    }

    function cancelList(uint _sellId) public handler returns(bool){
        marketplace.cancelList(_sellId);
        return true;
    }
    
    function transfer(address _receiver,address _token,uint256 _tokenId,uint256 _amountOfToken) public handler returns(bool){
        marketplace.transfer(_receiver,_token,_tokenId,_amountOfToken);
        return true;
    }
    
    function makeOffer(uint256 _sellId,uint256 _price) public handler returns(bool){
        marketplace.makeOffer(_sellId,_price);
        return true;
    }
    
    function acceptOffer(uint256 _sellId,uint256 _offerCount) public handler returns(bool){
        marketplace.acceptOffer(_sellId,_offerCount);
        return true;
    }
    
    function cancelOffer(uint256 _sellId,uint256 _offerCount) public handler returns(bool){
        marketplace.cancelOffer(_sellId,_offerCount);
        return true;
    }
    
    function depositEscrow(uint256 _amount) public handler returns(bool){
        marketplace.withdrawEscrow(_amount);
        return true;
    }
    
    function withdrawEscrow(uint256 _amount) public handler returns(bool){
        marketplace.withdrawEscrow(_amount);
        return true;
    }
    
    function createAuction(address _token,uint256 _tokenId,uint256 _amountOfToken,uint256 _startPrice,uint256 _minIncrement,uint256 _startDate,uint256 _duration,bool _reserved) public handler returns(bool){
        marketplace.createAuction(_token,_tokenId,_amountOfToken,_startPrice,_minIncrement,_startDate,_duration,_reserved);
        return true;
    }
    
    function placeBid(uint256 _auctionId) public handler returns(bool){
        marketplace.placeBid(_auctionId);
        return true;
    }
    
    function cancelAuction(uint256 _auctionId) public handler returns(bool){
        marketplace.cancelAuction(_auctionId);
        return true;
    }
    
    function claimAuction(uint256 _auctionId) public handler returns(bool){
        marketplace.claimAuction(_auctionId);
        return true;
    }

    fallback() external payable {}
    receive() external payable {} 
}
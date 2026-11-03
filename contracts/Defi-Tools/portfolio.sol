//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./marketplace.sol";


/// @title Marketplace Portfolio
/// @author R Qiuincy Jones
/// @notice This is a portfolio contract that allows a single contract to custody assets from the 1155 marketplace
/// @dev this contravct works well with the 1155 marketplace contract

contract portfolioLedger{
    string portfolioTokenURI;   //URI formart for users
    address public marketplaceAddress; //address of marketplace Contract

    uint public totalAccounts = 0;
    
    // The marketplace's keys go to whoever deploys this ledger, since the ledger itself can't use them
    constructor(uint _totalHandlers,string memory _URI,string memory _marketplaceName){
        portfolioTokenURI = _URI;
        Marketplace market = new Marketplace(_totalHandlers,_URI,_marketplaceName);
        marketplaceAddress = address(market);
        market.safeTransferFrom(address(this), msg.sender, market.handlerToken(), _totalHandlers, "");
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
        require(bytes(_account).length > 0, "Account name cannot be empty");

        address portfolioContractAddress; 
        portfolioContractAddress = address(new Portfolio(portfolioTokenURI,_account,address(this),marketplaceAddress,msg.sender));
        ledger[_account] = Ledger(_account,totalAccounts,portfolioContractAddress,true);
        numbLedger[totalAccounts] = numberLedger(_account,portfolioContractAddress,true);
        totalAccounts++;
        return ("new account created", portfolioContractAddress);
    }
    //check and view a user Account, by name or by number
    function checkAccount(string memory _account,uint accountNumber)public view returns(string memory,address,bool){
        if(ledger[_account].exist){
            return (ledger[_account].account,ledger[_account].portfolio,true);
        }else if(numbLedger[accountNumber].exist){
            return (numbLedger[accountNumber].account,numbLedger[accountNumber].portfolio,true);
        }else{
            return ("none",0x0000000000000000000000000000000000000000,false);
        }
    }
    //forward funds from one user name to another
    function forwardFunds(string memory _reciver)external payable returns(bool){
        require(bytes(_reciver).length > 0, "Receiver name cannot be empty");
        require(msg.value > 0, "Amount must be greater than 0");
        require(ledger[_reciver].exist == true, "User does not exist");
        (bool sent,) = payable(ledger[_reciver].portfolio).call{value: msg.value}("");
        require(sent, "Payment failed");
        return true;
    }
}

contract Portfolio is ERC1155{
    uint public handlerToken;
    string public accountName;
    uint public marketplaceCount =0;

    Marketplace public marketplace;
    portfolioLedger public DAppLedger;
    address public currentOwner;

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
        DAppLedger = portfolioLedger(_DAppLedger);
        marketplace = Marketplace(_marketplace);
        
        logNewMarketPlace(_marketplace);
    }
    modifier broker{
        require(marketplace.balanceOf(msg.sender,marketplace.handlerToken()) >= 1, "broker does not hold handler token");
        _;
    }
    modifier handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }
    // Keeps currentOwner right when the key is sold or moved, so a broker can still reset it
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for(uint i = 0; i < ids.length; i++){
            if(ids[i] == handlerToken && to != address(0)){
                currentOwner = to;
            }
        }
    }
    function resetOwner(address _newOwner) public broker returns(address){
        require(_newOwner != address(0), "New owner address cannot be zero");
        require(_newOwner != currentOwner, "New owner cannot be the same as the current owner");

        _burn(currentOwner,handlerToken,1);
        _mint(_newOwner,handlerToken,1, "");

        emit changedOwner("The registerd broker has chaged the owner of this contract",_newOwner);
        return _newOwner;
    }
    function logNewMarketPlace(address _marketplace) internal returns(bool){
        require(savedmarketplace[_marketplace].exist == false, "Markeplace already exist");
        string memory name = Marketplace(_marketplace).marketplaceName();
        savedmarketplace[_marketplace] = savedMarketPlaces(_marketplace,name,true);
        marketplaceNumber[marketplaceCount] = savedMarketPlaces(_marketplace,name,true);
        marketplaceCount++;
        return true;
    }
    function saveMarketplace(address _marketplace)public handler returns(bool){
        require(_marketplace != address(0), "Marketplace address cannot be zero");
        require(savedmarketplace[_marketplace].exist == false, "Markeplace already exist");

        logNewMarketPlace(_marketplace);
        return true;
    }

    // Marks the slot as removed. Other marketplaces keep their numbers
    function deleteMarketplace(uint _marketplaceIndex)public handler returns(bool){
        require(_marketplaceIndex < marketplaceCount, "Marketplace index out of range");
        address saved = marketplaceNumber[_marketplaceIndex].marketplaceAddress;
        require(saved != address(0), "Marketplace was already removed");
        require(saved != address(marketplace), "Marketplace is in use");

        delete savedmarketplace[saved];
        marketplaceNumber[_marketplaceIndex] = savedMarketPlaces(0x0000000000000000000000000000000000000000,"removed",false);
        return true;
    }

    function viewSavedMarketPlaces(uint _marketplaceIndex)public view handler returns(address,string memory,uint){
        require(_marketplaceIndex < marketplaceCount, "Marketplace index out of range");
        return (marketplaceNumber[_marketplaceIndex].marketplaceAddress,marketplaceNumber[_marketplaceIndex].marketplaceName,_marketplaceIndex);
    }

    function changeMarketplace(Marketplace _marketplace) public handler returns(Marketplace){
        require(address(_marketplace) != address(0), "Marketplace address cannot be zero");
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
    // Moves money out of the portfolio, such as what came back from withdrawEscrow
    function withdrawFunds(address _to,uint256 _amount) public handler returns(bool){
        require(_to != address(0), "Invalid address");
        (bool sent,) = payable(_to).call{value: _amount}("");
        require(sent, "Payment failed");
        return true;
    }
    // A portfolio holding tokens must approve the marketplace before it can list or transfer them
    function approveMarketplace(address _token,bool _approved) public handler returns(bool){
        IERC1155(_token).setApprovalForAll(address(marketplace),_approved);
        return true;
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
    
    // Pays from the portfolio's balance, topped up by anything sent with the call
    function makeOffer(uint256 _sellId,uint256 _price) public payable handler returns(bool){
        marketplace.makeOffer{value: _price}(_sellId,_price);
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
    
    // Pays from the portfolio's balance, topped up by anything sent with the call
    function depositEscrow(uint256 _amount) public payable handler returns(bool){
        marketplace.depositEscrow{value: _amount}();
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
    
    function placeBid(uint256 _auctionId) public payable handler returns(bool){
        marketplace.placeBid{value: msg.value}(_auctionId);
        return true;
    }
    
    function cancelAuction(uint256 _auctionId) public handler returns(bool){
        marketplace.cancelAuction(_auctionId);
        return true;
    }
    
    function claimAuction(uint256 _auctionId) public handler returns(bool){
        return marketplace.claimAuction(_auctionId);
    }

    //ERC1155Received fuctions, so a portfolio can hold what it buys
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {} 
}

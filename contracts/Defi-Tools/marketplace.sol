//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title 1155 Marketplace
/// @author R Quincy Jones
/// @notice This contract is a for from https://github.com/TronzitVeca/ERC1155-Marketplace-Contract that acts as a token marketplace
/// @dev This contract works with the profile contract. Listed tokens stay with the seller until a sale,
/// and auctioned tokens are held here until the auction closes, so the seller must approve this contract
/// on the token. Sale money waits in escrowAmount, and each person collects their own with withdrawEscrow.
/// A sale or auction keeps the fee in force when it was created.

contract Marketplace is ERC1155, ReentrancyGuard {

    uint256 public constant MAX_MARKETPLACE_FEE = 20;
    uint256 public constant MAX_AUCTION_TIME = 365 days;

    uint256 public marketplaceFee = 5;
    string public marketplaceName;

    mapping (uint => address) public recipient;
    mapping (uint => uint) public fee;
    uint256 public recipientCount;
    /// @notice Fee money no recipient was assigned, which a key holder can collect
    uint256 public feeReserve;

    mapping (uint => SellList) public sales;
    uint256 public salesId;

    mapping (uint => mapping (uint => OfferData)) public offerInfo;
    mapping (uint => uint) public offerCount;

    mapping (address => uint) public escrowAmount;
    /// @notice The part of escrowAmount backing open offers, which can't be withdrawn until they close
    mapping (address => uint) public lockedEscrow;

    mapping (uint => AuctionData) public auction;
    uint256 public auctionId;
    uint public handlerToken;

    /// @notice The fee percent each sale and auction was created under
    mapping (uint => uint) public listFee;
    mapping (uint => uint) public auctionFee;
    /// @notice Auction tokens held for a winner who hasn't collected them
    mapping (uint => HeldTokens) public heldTokens;
    bool private receivingAuctionTokens;


    function viewAllAssetsAndBids() public view returns (SellList[] memory) {
        SellList[] memory allAssets = new SellList[](salesId);

        for (uint256 i = 0; i < salesId; i++) {
            allAssets[i] = sales[i];
        }

        return allAssets;
    }


    function viewAuction(uint256 _auctionId) public view returns (AuctionData memory) {
        return auction[_auctionId];
    }


    /// @notice This is the Sell struct, the basic structures contain the owner of the selling tokens.
    struct SellList {
        address seller;
        address token;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 deadline;
        uint256 price;
        bool isSold;
    }

    struct OfferData {
        address offerAddress;
        uint256 offerPrice;
        bool isAccepted;
    }

    struct AuctionData {
        address creator;
        address token;
        address highestBidder;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 highestBid;
        uint256 startPrice;
        uint256 minIncrement;
        uint256 startDate;
        uint256 duration;
        Action action;
    }

    struct HeldTokens {
        address winner;
        address token;
        uint256 tokenId;
        uint256 amountOfToken;
    }

    enum Action {
        RESERVED, STARTED
    }
     /// @notice This is the emitted event, when a offer for a certain amount of tokens.
    event SellEvent (
        address _seller,
        address _token,
        uint256 _offerId,
        uint256 _tokenId,
        uint256 _amount
    );

    /// @notice This is the emitted event, when a sell is canceled.
    event CanceledSell (
        address _seller,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken
    );

    /// @notice This is the emitted event, when a buy is made.
    event BuyEvent (
        address _buyer,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _price
    );

    /// @notice The auction closed and the creator was paid. The tokens wait here for the winner.
    event AuctionTokensHeld (
        uint256 _auctionId,
        address _winner
    );

    /// @notice The auctioned token no longer exists, so the winning bid went back into the winner's escrow.
    event AuctionRefunded (
        uint256 _auctionId,
        address _bidder,
        uint256 _bid
    );

    //change to handler token
    constructor(uint _totalHandlers,string memory _URI,string memory _marketplaceName) ERC1155(_URI)   {
        require(_totalHandlers > 0, "at least one handler is required");
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,_totalHandlers, "");
        marketplaceName = _marketplaceName;
    }

    /// @dev Credits the seller and the fee recipients. Whatever no recipient gets goes to feeReserve
    function settle(address _seller, uint256 _amount, uint256 _feePercent) internal {
        uint256 feePrice = _amount * _feePercent / 100;
        escrowAmount[_seller] += _amount - feePrice;

        uint256 paid = 0;
        for (uint i = 0; i < recipientCount; i++) {
            uint256 share = feePrice * fee[i] / 100;
            escrowAmount[recipient[i]] += share;
            paid += share;
        }
        feeReserve += feePrice - paid;
    }

    function send(address _to, uint256 _amount) internal {
        (bool sent,) = payable(_to).call{value: _amount}("");
        require(sent, "Payment failed");
    }

    /**
        @param _newFee This is new marketplace fee amount
    **/
    function updateTotalFee(
        uint256 _newFee
    ) external onlyAdmin {
        require(_newFee <= MAX_MARKETPLACE_FEE, "updateFee: Fee is above the limit");
        // Set the new Marketplace fee
        marketplaceFee = _newFee;
    }
    
    /** 
        @param _recipient These are the updated recipient addresses of the fees.
        @param _fee These are the updated percentages of the fee for the recipients to receive. They can't add up to more than 100.
    **/
    function updateFeeAndRecipient(
        address[] memory _recipient, 
        uint256[] memory _fee
    ) external onlyAdmin {
        // _recipient and _fee counts should be the same
        require(_recipient.length == _fee.length, "updateFee: Not match");
        
        // Reset the recipientCount as updated data
        recipientCount = _fee.length;

        // Reset recipient and fee with newly data
        uint256 total = 0;
        for (uint i = 0; i < recipientCount; i++) {
            require(_recipient[i] != address(0), "updateFee: Invalid recipient");
            recipient[i] = _recipient[i];
            fee[i] = _fee[i];
            total += _fee[i];
        }
        require(total <= 100, "updateFee: Shares cannot be above 100");
    }

    /**
        @dev Collects fee money that no recipient was assigned
    **/
    function withdrawFeeReserve(
        address _to,
        uint256 _amount
    ) external onlyAdmin nonReentrant returns (bool) {
        require(_amount <= feeReserve, "withdrawFeeReserve: lower amount");
        feeReserve -= _amount;
        send(_to, _amount);
        return true;
    }

    /** 
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be sold in the offer.
        @param _deadline This is the final date in (seconds) so the offer ends.
        @param _price This is the full price for the amountOfToken that user passed as the param.
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the sell is created successfully.
    **/
    function createList(
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _deadline,
        uint256 _price
    ) external returns (bool) {
        require(_token.code.length > 0, "The token needs to be a contract");
        require(_amountOfToken > 0, "The amount of tokens to sell, needs to be greater than 0");
        require(_price > 0, "The full price for the tokens need to be greater than 0");
        require(_deadline > 3600, "The deadline needs to be greater than 1 hour");

        listFee[salesId] = marketplaceFee;
        sales[salesId] = SellList (
            msg.sender,
            _token,
            _tokenId,
            _amountOfToken,
            block.timestamp + _deadline,
            _price,
            false
        );

        emit SellEvent(
            msg.sender,
            _token,
            salesId,
            _tokenId,
            _amountOfToken
        );

        salesId ++;

        return true;
    }

    /**
        @param _sellId This is the ID of the SellList that's stored in mapping function.
        @dev The seller's money waits in escrow, and anything paid above the price is sent back.
    **/
    function buyListToken(
        uint256 _sellId
    ) external payable nonReentrant returns (bool) {
        SellList memory sale = sales[_sellId];
        require(sale.seller != address(0), "buyToken: The sale does not exist.");
        require(sale.isSold != true, "buyToken: The tokends were bought.");
        require(block.timestamp <= sale.deadline, "buyToken: The sale has ended.");
        require(msg.value >= sale.price, "buyToken: Needs to be greater or equal to the price.");

        sales[_sellId].isSold = true;
        settle(sale.seller, sale.price, listFee[_sellId]);

        IERC1155(sale.token).safeTransferFrom(
            sale.seller,
            msg.sender,
            sale.tokenId,
            sale.amountOfToken,
            ""
        );

        emit BuyEvent(msg.sender, sale.token, sale.tokenId, sale.amountOfToken, sale.price);

        if (msg.value > sale.price) {
            send(msg.sender, msg.value - sale.price);
        }

        return true;
    }

    /** 
        @param _sellId The ID of the sell that you want to cancel.
    **/
    function cancelList(
        uint256 _sellId
    ) external returns (bool) {
        SellList memory sale = sales[_sellId];
        require(sale.seller == msg.sender, "Cancel: should be the owner of the sell.");
        require(sale.isSold != true, "Cancel: already sold.");

        delete sales[_sellId];

        emit CanceledSell(
            sale.seller,
            sale.token,
            sale.tokenId,
            sale.amountOfToken
        );

        return true;
    }

    /**
        @param _receiver This is the address which will be receive the token.
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be transferred.
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the sell is created successfully.
    **/
    function transfer(
        address _receiver,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken
    ) external nonReentrant returns (bool) {
        IERC1155(_token).safeTransferFrom(
            msg.sender, 
            _receiver, 
            _tokenId, 
            _amountOfToken, 
            ""
        );

        return true;

    }

    /**
        @param _sellId The ID of the sell that you want to make an offer.
        @param _price The offer price for _sellId.
        @dev The money stays locked in escrow until the offer is accepted or cancelled.
    **/
    function makeOffer(
        uint256 _sellId,
        uint256 _price
    ) external payable returns (bool) {
        SellList memory sale = sales[_sellId];
        require(_price > 0, "makeOffer: the offer needs a price");
        require(msg.value == _price, "makeOffer: msg.value should be the _price");
        require(sale.seller != address(0), "makeOffer: the sale does not exist");
        require(sale.seller != msg.sender, "makeOffer: seller shouldn't offer");
        require(sale.isSold != true, "makeOffer: already sold.");
        require(block.timestamp <= sale.deadline, "makeOffer: the sale has ended");

        uint256 counter = offerCount[_sellId];

        offerInfo[_sellId][counter] = OfferData (
            msg.sender,
            msg.value,
            false
        );

        offerCount[_sellId] ++;

        escrowAmount[msg.sender] += msg.value;
        lockedEscrow[msg.sender] += msg.value;

        return true;
    }

    /**
        @param _sellId The ID of the sell that you want to make an offer.
        @param _offerCount The offer count to be accepted from the seller.
    **/
    function acceptOffer(
        uint256 _sellId,
        uint256 _offerCount
    ) external nonReentrant returns (bool) {
        SellList memory sale = sales[_sellId];
        OfferData memory offer = offerInfo[_sellId][_offerCount];

        require(sale.isSold != true, "acceptOffer: already sold.");
        require(sale.seller == msg.sender, "acceptOffer: not seller");
        require(block.timestamp <= sale.deadline, "acceptOffer: the sale has ended");
        require(offer.offerAddress != address(0), "acceptOffer: the offer does not exist");
        require(offer.isAccepted == false, "acceptOffer: already accepted");

        sales[_sellId].isSold = true;
        offerInfo[_sellId][_offerCount].isAccepted = true;

        lockedEscrow[offer.offerAddress] -= offer.offerPrice;
        escrowAmount[offer.offerAddress] -= offer.offerPrice;
        settle(sale.seller, offer.offerPrice, listFee[_sellId]);

        IERC1155(sale.token).safeTransferFrom(
            sale.seller,
            offer.offerAddress,
            sale.tokenId,
            sale.amountOfToken,
            ""
        );

        return true;

    }


    /**
        @param _sellId The ID of the sell that you want to make an offer.
        @param _offerCount The offer count to be cancelled from the offerAddress.
    **/
    function cancelOffer(
        uint256 _sellId,
        uint256 _offerCount
    ) external nonReentrant returns (bool) {
        OfferData memory offer = offerInfo[_sellId][_offerCount];

        require(msg.sender == offer.offerAddress, "cancelOffer: not offerAddress");
        require(offer.isAccepted == false, "acceptOffer: already accepted");

        delete offerInfo[_sellId][_offerCount];
        lockedEscrow[msg.sender] -= offer.offerPrice;
        escrowAmount[msg.sender] -= offer.offerPrice;

        send(msg.sender, offer.offerPrice);

        return true;
    }

    /**
        @dev This function used to deposit the Matic on this platform 
    **/
    function depositEscrow() external payable returns (bool) {
        escrowAmount[msg.sender] += msg.value;

        return true;

    }

    
    /**
        @dev This function used to withdraw the Matic on this platform 
        @param _amount This is the amount of the Matic to withdraw from the marketplace
    **/
    function withdrawEscrow(
        uint256 _amount
    ) external nonReentrant returns (bool) {
        require(_amount <= escrowAmount[msg.sender] - lockedEscrow[msg.sender], "withdrawEscrow: lower amount");

        escrowAmount[msg.sender] -= _amount;

        send(msg.sender, _amount);

        return true;

    }


    /** 
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be created in auction.
        @param _startPrice This is the start Price of the auction.
        @param _minIncrement This is the min increment of the bids in this auction.
        @param _startDate This is the start date in (seconds) so the auction starts.
        @param _duration This is the duration of this auction.
        @param _reserved 1: reserved acution 0: normal auction
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the auction is created successfully.
    **/
    function createAuction(
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _startPrice,
        uint256 _minIncrement,
        uint256 _startDate,
        uint256 _duration,
        bool _reserved
    ) external nonReentrant returns (bool) {
        require(_token.code.length > 0, "createAuction: The token needs to be a contract");
        require(_amountOfToken > 0, "createAuction: The amount of tokens to sell, needs to be greater than 0");
        require(_startPrice > 0, "createAuction: The startPrice for the tokens need to be greater than 0");
        require(_duration > 86400, "createAuction: The deadline should to be greater than 1 day");
        require(_duration <= MAX_AUCTION_TIME, "createAuction: The duration is too long");
        require(_minIncrement > 0, "createAuction: The minIncrement should be bigger than 0");
        require(_startDate > block.timestamp, "createAuction: The start date should be after now");
        require(_startDate <= block.timestamp + MAX_AUCTION_TIME, "createAuction: The start date is too far away");

        Action action;

        if (!_reserved) {
            action = Action.STARTED;
        }
        
        auction[auctionId] = AuctionData (
            msg.sender,
            _token,
            address(0),
            _tokenId,
            _amountOfToken,
            0,
            _startPrice,
            _minIncrement,
            _startDate,
            _duration,
            action
        );
        
        auctionFee[auctionId] = marketplaceFee;
        auctionId ++;

        receivingAuctionTokens = true;
        IERC1155(_token).safeTransferFrom(msg.sender, address(this), _tokenId, _amountOfToken, "");
        receivingAuctionTokens = false;

        return true;

    }

    /// @dev Accepts only the tokens createAuction moves in, so nothing else can get stuck here
    function onERC1155Received(address _operator, address, uint256, uint256, bytes memory) external view returns (bytes4) {
        require(_operator == address(this) && receivingAuctionTokens, "this contract does not accept tokens");
        return this.onERC1155Received.selector;
    }

    /*
        @param _auctionId Users can bid to the _auctionId with value
        @dev The bid it replaces goes back into that bidder's escrow
    */
    function placeBid(
        uint256 _auctionId
    ) external payable returns (bool) {
        AuctionData memory auctionInfo = auction[_auctionId];

        require(auctionInfo.creator != address(0), "placeBid: The auction does not exist");

        uint256 lowestBid = auctionInfo.highestBidder == address(0)
            ? auctionInfo.startPrice
            : auctionInfo.highestBid + auctionInfo.minIncrement;

        require(msg.value >= lowestBid, "placeBid: Bid amount should be bigger than highestBid");
        require(msg.sender != auctionInfo.creator, "placeBid: Creator can't bid");
        require(block.timestamp >= auctionInfo.startDate, "placeBid: Bid should be after the startDate");
        require(auctionInfo.action == Action.RESERVED || auctionInfo.startDate + auctionInfo.duration > block.timestamp, "placeBid: It is Ended");

        if (auctionInfo.highestBidder != address(0)) {
            escrowAmount[auctionInfo.highestBidder] += auctionInfo.highestBid;
        }

        /*
            If the auction is reserved, set the startDate as now
            action as Action Enum - STARTED
        */
        if (auctionInfo.action == Action.RESERVED) {
            auction[_auctionId].startDate = block.timestamp;
            auction[_auctionId].action = Action.STARTED;
        }

        auction[_auctionId].highestBidder = msg.sender;
        auction[_auctionId].highestBid = msg.value;

        return true;

    }

    /*
        @param _auctionId The auction Creator can cancel the auction and take the tokens back
    */
    function cancelAuction(
        uint256 _auctionId
    ) external nonReentrant returns (bool) {
        AuctionData memory auctionInfo = auction[_auctionId];

        require(msg.sender == auctionInfo.creator, "cancelAuction: Only auction creator can cancel it");
        require(block.timestamp > auctionInfo.startDate + auctionInfo.duration, "cancelAuction: The time should be after endDate");
        require(auctionInfo.highestBidder == address(0), "cancelAuction: There should be not highestBidder");

        delete auction[_auctionId];
        delete auctionFee[_auctionId];

        IERC1155(auctionInfo.token).safeTransferFrom(
            address(this),
            auctionInfo.creator,
            auctionInfo.tokenId,
            auctionInfo.amountOfToken,
            ""
        );

        return true;

    }

    /*
        @param _auctionId The winner or the creator can close a finished auction, once
        @dev The creator is paid here whatever the winner does. Tokens are only sent straight away when the
        winner calls, so the winner's code never runs on the creator's call. Otherwise, or if the winner's
        address refuses them, the tokens wait for collectAuctionTokens.
        @return True if the winner received the tokens in this call.
    */
    function claimAuction(
        uint256 _auctionId
    ) external nonReentrant returns (bool) {
        AuctionData memory auctionInfo = auction[_auctionId];

        require(auctionInfo.highestBidder != address(0), "claimAuction: The auction has no winner");
        require(msg.sender == auctionInfo.highestBidder || msg.sender == auctionInfo.creator, "claimAuction: The msg.sender should be the highest Bidder or the creator");
        require(block.timestamp > auctionInfo.startDate + auctionInfo.duration, "claimAuction: The time should be after endDate");

        uint256 feePercent = auctionFee[_auctionId];
        delete auction[_auctionId];
        delete auctionFee[_auctionId];

        // Calling a token with no code would revert outside the try, and lock the bid
        if (auctionInfo.token.code.length == 0) {
            escrowAmount[auctionInfo.highestBidder] += auctionInfo.highestBid;
            emit AuctionRefunded(_auctionId, auctionInfo.highestBidder, auctionInfo.highestBid);
            return false;
        }

        settle(auctionInfo.creator, auctionInfo.highestBid, feePercent);

        if (msg.sender == auctionInfo.highestBidder) {
            try IERC1155(auctionInfo.token).safeTransferFrom(
                address(this),
                auctionInfo.highestBidder,
                auctionInfo.tokenId,
                auctionInfo.amountOfToken,
                ""
            ) {
                return true;
            } catch {}
        }

        heldTokens[_auctionId] = HeldTokens(auctionInfo.highestBidder, auctionInfo.token, auctionInfo.tokenId, auctionInfo.amountOfToken);
        emit AuctionTokensHeld(_auctionId, auctionInfo.highestBidder);
        return false;
    }

    /*
        @param _auctionId The closed auction whose tokens are waiting here
        @param _to Where to send them, which can be another address if the winner's own can't receive them
    */
    function collectAuctionTokens(
        uint256 _auctionId,
        address _to
    ) external nonReentrant returns (bool) {
        HeldTokens memory held = heldTokens[_auctionId];
        require(held.winner != address(0), "collectAuctionTokens: Nothing is held for this auction");
        require(msg.sender == held.winner, "collectAuctionTokens: Only the winner can collect");

        delete heldTokens[_auctionId];

        IERC1155(held.token).safeTransferFrom(address(this), _to, held.tokenId, held.amountOfToken, "");

        return true;
    }

    /**
        @dev This is the modifier to make - only handler can access the function
    **/
    modifier onlyAdmin{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }

}

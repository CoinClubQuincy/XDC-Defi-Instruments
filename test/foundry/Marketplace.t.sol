// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./Mocks.sol";
import "../../contracts/Defi-Tools/portfolio.sol";

contract MarketplaceTest is Test {
    event SellEvent(address _seller, address _token, uint256 _offerId, uint256 _tokenId, uint256 _amount);
    event CanceledSell(address _seller, address _token, uint256 _tokenId, uint256 _amountOfToken);

    address admin = makeAddr("admin");
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    address buyer2 = makeAddr("buyer2");
    address feeTaker = makeAddr("feeTaker");
    MockToken token;
    Marketplace market;
    uint startDate;
    uint constant DAY = 1 days;

    function setUp() public {
        token = new MockToken();
        token.mint(seller, 1, 10);
        vm.prank(admin);
        market = new Marketplace(1, "uri", "Market");
        vm.prank(seller);
        token.setApprovalForAll(address(market), true);
        vm.deal(buyer, 100 ether);
        vm.deal(buyer2, 100 ether);
        startDate = block.timestamp + 1;
    }

    function list() internal returns (uint id) {
        id = market.salesId();
        vm.prank(seller);
        market.createList(address(token), 1, 2, 2 hours, 1 ether);
    }

    function auctionOf(bool reserved) internal returns (uint id) {
        id = market.auctionId();
        vm.prank(seller);
        market.createAuction(address(token), 1, 2, 1 ether, 0.5 ether, startDate, 2 * DAY, reserved);
    }

    function highestBidder(uint id) internal view returns (address who) {
        who = market.viewAuction(id).highestBidder;
    }

    function isSold(uint id) internal view returns (bool sold) {
        (,,,,,, sold) = market.sales(id);
    }

    // Listings

    function test_BuyMovesTokensAndCreditsTheSeller() public {
        uint id = list();
        vm.prank(buyer);
        market.buyListToken{value: 1 ether}(id);
        assertEq(token.balanceOf(buyer, 1), 2);
        assertEq(market.escrowAmount(seller), 0.95 ether);
        assertEq(market.feeReserve(), 0.05 ether);
        assertTrue(isSold(id));

        vm.prank(seller);
        market.withdrawEscrow(0.95 ether);
        assertEq(seller.balance, 0.95 ether);
    }

    function test_BuyRefundsOverpayment() public {
        uint id = list();
        vm.prank(buyer);
        market.buyListToken{value: 3 ether}(id);
        assertEq(buyer.balance, 99 ether);
        assertEq(address(market).balance, 1 ether);
    }

    function test_ASaleHappensOnce() public {
        uint id = list();
        vm.prank(buyer);
        market.buyListToken{value: 1 ether}(id);
        vm.prank(buyer2);
        vm.expectRevert("buyToken: The tokends were bought.");
        market.buyListToken{value: 1 ether}(id);
        assertEq(token.balanceOf(seller, 1), 8);
    }

    function test_BuyChecksPriceDeadlineAndExistence() public {
        uint id = list();
        vm.startPrank(buyer);
        vm.expectRevert("buyToken: Needs to be greater or equal to the price.");
        market.buyListToken{value: 0.5 ether}(id);
        vm.expectRevert("buyToken: The sale does not exist.");
        market.buyListToken{value: 1 ether}(id + 1);
        vm.warp(block.timestamp + 2 hours + 1);
        vm.expectRevert("buyToken: The sale has ended.");
        market.buyListToken{value: 1 ether}(id);
        vm.stopPrank();
    }

    function test_FailedTransferRefundsTheBuyer() public {
        uint id = list();
        vm.prank(seller);
        token.setApprovalForAll(address(market), false);
        vm.prank(buyer);
        vm.expectRevert();
        market.buyListToken{value: 1 ether}(id);
        assertEq(buyer.balance, 100 ether);
    }

    function test_CancelListRemovesTheSale() public {
        uint id = list();
        vm.prank(buyer);
        vm.expectRevert("Cancel: should be the owner of the sell.");
        market.cancelList(id);
        vm.prank(seller);
        vm.expectEmit(true, true, true, true);
        emit CanceledSell(seller, address(token), 1, 2);
        market.cancelList(id);
        vm.prank(buyer);
        vm.expectRevert("buyToken: The sale does not exist.");
        market.buyListToken{value: 1 ether}(id);
    }

    function test_CreateListChecksItsInput() public {
        vm.startPrank(seller);
        vm.expectRevert("The token needs to be a contract");
        market.createList(buyer, 1, 1, 2 hours, 1 ether);
        vm.expectRevert("The amount of tokens to sell, needs to be greater than 0");
        market.createList(address(token), 1, 0, 2 hours, 1 ether);
        vm.expectRevert("The full price for the tokens need to be greater than 0");
        market.createList(address(token), 1, 1, 2 hours, 0);
        vm.expectRevert("The deadline needs to be greater than 1 hour");
        market.createList(address(token), 1, 1, 3600, 1 ether);
        vm.stopPrank();
    }

    function test_SellEventReportsTheRealId() public {
        vm.expectEmit(true, true, true, true);
        emit SellEvent(seller, address(token), 0, 1, 2);
        list();
    }

    function test_TransferMovesTheCallersTokens() public {
        vm.prank(seller);
        market.transfer(buyer, address(token), 1, 3);
        assertEq(token.balanceOf(buyer, 1), 3);
    }

    // Offers

    function test_AcceptedOfferPaysTheSellerNotTheBuyer() public {
        uint id = list();
        vm.prank(buyer);
        market.makeOffer{value: 0.8 ether}(id, 0.8 ether);
        assertEq(market.lockedEscrow(buyer), 0.8 ether);

        vm.prank(seller);
        market.acceptOffer(id, 0);
        assertEq(market.escrowAmount(seller), 0.76 ether);
        assertEq(market.feeReserve(), 0.04 ether);
        assertEq(market.escrowAmount(buyer), 0);
        assertEq(market.lockedEscrow(buyer), 0);
        assertEq(buyer.balance, 99.2 ether);
        assertEq(token.balanceOf(buyer, 1), 2);
        assertTrue(isSold(id));
    }

    function test_AnotherOffererGetsTheirMoneyBackAfterASale() public {
        uint id = list();
        vm.prank(buyer);
        market.makeOffer{value: 0.8 ether}(id, 0.8 ether);
        vm.prank(buyer2);
        market.makeOffer{value: 0.5 ether}(id, 0.5 ether);

        vm.prank(seller);
        market.acceptOffer(id, 0);

        vm.prank(seller);
        vm.expectRevert("acceptOffer: already sold.");
        market.acceptOffer(id, 1);

        vm.prank(buyer2);
        market.cancelOffer(id, 1);
        assertEq(buyer2.balance, 100 ether);
    }

    function test_OfferMoneyIsLockedUntilCancelled() public {
        uint id = list();
        vm.startPrank(buyer);
        market.makeOffer{value: 0.8 ether}(id, 0.8 ether);
        vm.expectRevert("withdrawEscrow: lower amount");
        market.withdrawEscrow(0.1 ether);
        market.cancelOffer(id, 0);
        vm.expectRevert("cancelOffer: not offerAddress");
        market.cancelOffer(id, 0);
        vm.stopPrank();
        assertEq(buyer.balance, 100 ether);
        assertEq(market.escrowAmount(buyer), 0);
    }

    function test_OfferChecksItsInput() public {
        uint id = list();
        vm.startPrank(buyer);
        vm.expectRevert("makeOffer: the offer needs a price");
        market.makeOffer(id, 0);
        vm.expectRevert("makeOffer: msg.value should be the _price");
        market.makeOffer{value: 1 ether}(id, 2 ether);
        vm.expectRevert("makeOffer: the sale does not exist");
        market.makeOffer{value: 1 ether}(id + 1, 1 ether);
        vm.stopPrank();
        vm.deal(seller, 1 ether);
        vm.prank(seller);
        vm.expectRevert("makeOffer: seller shouldn't offer");
        market.makeOffer{value: 1 ether}(id, 1 ether);
    }

    function test_AcceptChecksItsInput() public {
        uint id = list();
        vm.prank(buyer);
        market.makeOffer{value: 1 ether}(id, 1 ether);
        vm.prank(buyer);
        vm.expectRevert("acceptOffer: not seller");
        market.acceptOffer(id, 0);
        vm.prank(seller);
        vm.expectRevert("acceptOffer: the offer does not exist");
        market.acceptOffer(id, 1);
        vm.warp(block.timestamp + 2 hours + 1);
        vm.prank(seller);
        vm.expectRevert("acceptOffer: the sale has ended");
        market.acceptOffer(id, 0);
    }

    // Escrow

    function test_EscrowCanBeFullyWithdrawn() public {
        vm.startPrank(buyer);
        market.depositEscrow{value: 2 ether}();
        vm.expectRevert("withdrawEscrow: lower amount");
        market.withdrawEscrow(3 ether);
        market.withdrawEscrow(2 ether);
        vm.stopPrank();
        assertEq(buyer.balance, 100 ether);
        assertEq(market.escrowAmount(buyer), 0);
    }

    function test_MarketplaceRefusesDirectPayments() public {
        vm.prank(buyer);
        (bool sent,) = address(market).call{value: 1 ether}("");
        assertFalse(sent);
    }

    // Fees

    function test_FeeSharesReachRecipientsAndTheRestGoesToTheReserve() public {
        address[] memory takers = new address[](1);
        uint[] memory shares = new uint[](1);
        takers[0] = feeTaker;
        shares[0] = 60;
        vm.prank(admin);
        market.updateFeeAndRecipient(takers, shares);

        uint id = list();
        vm.prank(buyer);
        market.buyListToken{value: 1 ether}(id);
        assertEq(market.escrowAmount(feeTaker), 0.03 ether);
        assertEq(market.feeReserve(), 0.02 ether);

        vm.prank(admin);
        market.withdrawFeeReserve(feeTaker, 0.02 ether);
        assertEq(feeTaker.balance, 0.02 ether);
        assertEq(market.feeReserve(), 0);
    }

    function test_FeeSettingsAreLimited() public {
        address[] memory takers = new address[](2);
        uint[] memory shares = new uint[](2);
        takers[0] = feeTaker;
        takers[1] = buyer;
        shares[0] = 60;
        shares[1] = 41;
        vm.startPrank(admin);
        vm.expectRevert("updateFee: Shares cannot be above 100");
        market.updateFeeAndRecipient(takers, shares);
        vm.expectRevert("updateFee: Fee cannot be above 100");
        market.updateTotalFee(101);
        vm.expectRevert("updateFee: Not match");
        market.updateFeeAndRecipient(takers, new uint[](1));
        takers[1] = address(0);
        shares[1] = 1;
        vm.expectRevert("updateFee: Invalid recipient");
        market.updateFeeAndRecipient(takers, shares);
        vm.expectRevert("withdrawFeeReserve: lower amount");
        market.withdrawFeeReserve(admin, 1);
        vm.stopPrank();
    }

    function test_OnlyKeyHoldersSetFees() public {
        vm.startPrank(buyer);
        vm.expectRevert("user does not hold handler token");
        market.updateTotalFee(1);
        vm.expectRevert("user does not hold handler token");
        market.updateFeeAndRecipient(new address[](0), new uint[](0));
        vm.expectRevert("user does not hold handler token");
        market.withdrawFeeReserve(buyer, 0);
        vm.stopPrank();
    }

    // Auctions

    function test_FullAuction() public {
        uint id = auctionOf(false);
        vm.warp(startDate);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(id);
        vm.prank(buyer2);
        market.placeBid{value: 2 ether}(id);
        assertEq(highestBidder(id), buyer2);
        assertEq(market.escrowAmount(buyer), 1 ether);

        vm.warp(startDate + 2 * DAY + 1);
        vm.prank(buyer2);
        assertTrue(market.claimAuction(id));
        assertEq(token.balanceOf(buyer2, 1), 2);
        assertEq(market.escrowAmount(seller), 1.9 ether);
        assertEq(market.feeReserve(), 0.1 ether);
    }

    function test_AuctionCanOnlyBeClaimedOnce() public {
        uint id = auctionOf(false);
        vm.warp(startDate);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(id);
        vm.warp(startDate + 2 * DAY + 1);
        vm.prank(buyer);
        market.claimAuction(id);
        vm.prank(buyer);
        vm.expectRevert("claimAuction: The auction has no winner");
        market.claimAuction(id);
        assertEq(token.balanceOf(buyer, 1), 2);
        assertEq(market.escrowAmount(seller), 0.95 ether);
    }

    function test_CreatorCanCloseAnAuctionForTheWinner() public {
        uint id = auctionOf(false);
        vm.warp(startDate);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(id);
        vm.warp(startDate + 2 * DAY + 1);
        vm.prank(seller);
        market.claimAuction(id);
        assertEq(token.balanceOf(buyer, 1), 2);
    }

    function test_WinnerIsRefundedIfTheTokensAreGone() public {
        uint id = auctionOf(false);
        vm.warp(startDate);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(id);
        vm.prank(seller);
        token.setApprovalForAll(address(market), false);
        vm.warp(startDate + 2 * DAY + 1);
        vm.prank(buyer);
        assertFalse(market.claimAuction(id));
        assertEq(market.escrowAmount(buyer), 1 ether);
        assertEq(market.escrowAmount(seller), 0);
        vm.prank(buyer);
        market.withdrawEscrow(1 ether);
        assertEq(buyer.balance, 100 ether);
    }

    function test_ABidderThatRefusesMoneyCannotBlockTheAuction() public {
        uint id = auctionOf(false);
        RefusesMoney refuser = new RefusesMoney();
        vm.deal(address(refuser), 1 ether);
        vm.warp(startDate);
        refuser.callWith(address(market), 1 ether, abi.encodeCall(Marketplace.placeBid, (id)));
        vm.prank(buyer);
        market.placeBid{value: 2 ether}(id);
        assertEq(highestBidder(id), buyer);
        assertEq(market.escrowAmount(address(refuser)), 1 ether);
    }

    function test_BidsFollowTheRules() public {
        uint id = auctionOf(false);
        vm.startPrank(buyer);
        vm.expectRevert("placeBid: Bid should be after the startDate");
        market.placeBid{value: 1 ether}(id);
        vm.warp(startDate);
        vm.expectRevert("placeBid: Bid amount should be bigger than highestBid");
        market.placeBid{value: 0.5 ether}(id);
        market.placeBid{value: 1 ether}(id);
        vm.expectRevert("placeBid: Bid amount should be bigger than highestBid");
        market.placeBid{value: 1.4 ether}(id);
        vm.warp(startDate + 2 * DAY);
        vm.expectRevert("placeBid: It is Ended");
        market.placeBid{value: 2 ether}(id);
        vm.stopPrank();
    }

    function test_NoBidsOnAuctionsThatDoNotExist() public {
        vm.prank(buyer);
        vm.expectRevert("placeBid: The auction does not exist");
        market.placeBid{value: 1 ether}(99);
        assertEq(buyer.balance, 100 ether);
    }

    function test_IncrementCanBeBiggerThanTheStartPrice() public {
        vm.prank(seller);
        market.createAuction(address(token), 1, 1, 1 ether, 5 ether, startDate, 2 * DAY, false);
        vm.warp(startDate);
        vm.startPrank(buyer);
        market.placeBid{value: 1 ether}(0);
        vm.expectRevert("placeBid: Bid amount should be bigger than highestBid");
        market.placeBid{value: 5 ether}(0);
        market.placeBid{value: 6 ether}(0);
        vm.stopPrank();
    }

    function test_CreatorCannotBid() public {
        uint id = auctionOf(false);
        vm.warp(startDate);
        vm.deal(seller, 1 ether);
        vm.prank(seller);
        vm.expectRevert("placeBid: Creator can't bid");
        market.placeBid{value: 1 ether}(id);
    }

    function test_ReservedAuctionStartsOnTheFirstBid() public {
        uint id = auctionOf(true);
        vm.warp(startDate + 30 * DAY);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(id);
        vm.warp(startDate + 30 * DAY + DAY);
        vm.prank(buyer);
        vm.expectRevert("claimAuction: The time should be after endDate");
        market.claimAuction(id);
        vm.warp(startDate + 30 * DAY + 2 * DAY + 1);
        vm.prank(buyer);
        market.claimAuction(id);
        assertEq(token.balanceOf(buyer, 1), 2);
    }

    function test_ClaimRules() public {
        uint id = auctionOf(false);
        vm.warp(startDate);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(id);
        vm.prank(buyer);
        vm.expectRevert("claimAuction: The time should be after endDate");
        market.claimAuction(id);
        vm.warp(startDate + 2 * DAY + 1);
        vm.prank(buyer2);
        vm.expectRevert("claimAuction: The msg.sender should be the highest Bidder or the creator");
        market.claimAuction(id);
    }

    function test_CancelAuctionRules() public {
        uint id = auctionOf(false);
        uint withBid = auctionOf(false);
        vm.warp(startDate);
        vm.prank(buyer);
        market.placeBid{value: 1 ether}(withBid);

        vm.prank(buyer);
        vm.expectRevert("cancelAuction: Only auction creator can cancel it");
        market.cancelAuction(id);
        vm.prank(seller);
        vm.expectRevert("cancelAuction: The time should be after endDate");
        market.cancelAuction(id);

        vm.warp(startDate + 2 * DAY + 1);
        vm.prank(seller);
        vm.expectRevert("cancelAuction: There should be not highestBidder");
        market.cancelAuction(withBid);
        vm.prank(seller);
        market.cancelAuction(id);
        vm.prank(buyer);
        vm.expectRevert("placeBid: The auction does not exist");
        market.placeBid{value: 1 ether}(id);
    }

    function test_CreateAuctionChecksItsInput() public {
        vm.startPrank(seller);
        vm.expectRevert("createAuction: The token needs to be a contract");
        market.createAuction(buyer, 1, 1, 1 ether, 1, startDate, 2 * DAY, false);
        vm.expectRevert("createAuction: The amount of tokens to sell, needs to be greater than 0");
        market.createAuction(address(token), 1, 0, 1 ether, 1, startDate, 2 * DAY, false);
        vm.expectRevert("createAuction: The startPrice for the tokens need to be greater than 0");
        market.createAuction(address(token), 1, 1, 0, 1, startDate, 2 * DAY, false);
        vm.expectRevert("createAuction: The deadline should to be greater than 1 day");
        market.createAuction(address(token), 1, 1, 1 ether, 1, startDate, DAY, false);
        vm.expectRevert("createAuction: The minIncrement should be bigger than 0");
        market.createAuction(address(token), 1, 1, 1 ether, 0, startDate, 2 * DAY, false);
        vm.expectRevert("createAuction: The start date should be after now");
        market.createAuction(address(token), 1, 1, 1 ether, 1, block.timestamp, 2 * DAY, false);
        vm.stopPrank();
    }

    function test_ListsSales() public {
        list();
        list();
        assertEq(market.viewAllAssetsAndBids().length, 2);
    }

    // Solvency

    function owed(address[5] memory people) internal view returns (uint total) {
        for (uint i = 0; i < people.length; i++) {
            total += market.escrowAmount(people[i]);
        }
        total += market.feeReserve();
    }

    /// Runs random actions, and after each one the contract must hold exactly what people are owed
    function testFuzz_ContractAlwaysHoldsWhatItOwes(uint256 seed, uint8 steps) public {
        address[3] memory bidders = [buyer, buyer2, feeTaker];
        address[5] memory people = [buyer, buyer2, feeTaker, seller, admin];
        vm.deal(feeTaker, 100 ether);
        uint total = bound(steps, 5, 40);

        address[] memory takers = new address[](1);
        uint[] memory shares = new uint[](1);
        takers[0] = feeTaker;
        shares[0] = 37;
        vm.prank(admin);
        market.updateFeeAndRecipient(takers, shares);
        token.mint(seller, 1, 1000);

        for (uint i = 0; i < total; i++) {
            act(uint(keccak256(abi.encode(seed, i))), bidders);
            assertEq(address(market).balance, owed(people) + activeBids());
        }
    }

    function newAuction(bool reserved) internal {
        vm.prank(seller);
        market.createAuction(address(token), 1, 1, 1 ether, 0.1 ether, block.timestamp + 1, DAY + 1, reserved);
    }

    function tryCall(address who, uint value, bytes memory data) internal {
        vm.prank(who);
        (bool ignored,) = address(market).call{value: value}(data);
        ignored;
    }

    function act(uint roll, address[3] memory bidders) internal {
        address who = bidders[roll % 3];
        uint amount = 1 + (roll >> 8) % 3 ether;
        uint sale = market.salesId() == 0 ? 0 : (roll >> 16) % market.salesId();
        uint auctionNumber = market.auctionId() == 0 ? 0 : (roll >> 24) % market.auctionId();
        uint offer = (roll >> 32) % 3;
        uint action = (roll >> 40) % 11;

        if (action == 0) {
            list();
        } else if (action == 1) {
            newAuction(roll % 2 == 0);
        } else if (action == 2) {
            tryCall(who, amount, abi.encodeCall(Marketplace.buyListToken, (sale)));
        } else if (action == 3) {
            tryCall(who, amount, abi.encodeCall(Marketplace.makeOffer, (sale, amount)));
        } else if (action == 4) {
            tryCall(seller, 0, abi.encodeCall(Marketplace.acceptOffer, (sale, offer)));
        } else if (action == 5) {
            tryCall(who, 0, abi.encodeCall(Marketplace.cancelOffer, (sale, offer)));
        } else if (action == 6) {
            tryCall(who, amount, abi.encodeCall(Marketplace.depositEscrow, ()));
        } else if (action == 7) {
            tryCall(who, 0, abi.encodeCall(Marketplace.withdrawEscrow, (amount)));
        } else if (action == 8) {
            tryCall(who, amount, abi.encodeCall(Marketplace.placeBid, (auctionNumber)));
        } else if (action == 9) {
            tryCall(who, 0, abi.encodeCall(Marketplace.claimAuction, (auctionNumber)));
        } else {
            vm.warp(block.timestamp + 1 hours + (roll >> 48) % (2 * DAY));
        }
    }

    function activeBids() internal view returns (uint total) {
        for (uint i = 0; i < market.auctionId(); i++) {
            total += market.viewAuction(i).highestBid;
        }
    }
}

contract PortfolioTest is Test {
    address brokerKey = makeAddr("broker");
    address user = makeAddr("user");
    address friend = makeAddr("friend");
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    MockToken token;
    portfolioLedger ledger;
    Marketplace market;
    Portfolio portfolio;

    function setUp() public {
        token = new MockToken();
        vm.prank(brokerKey);
        ledger = new portfolioLedger(2, "uri", "Market");
        market = Marketplace(ledger.marketplaceAddress());
        vm.prank(user);
        (, address made) = ledger.createAccount("alice");
        portfolio = Portfolio(payable(made));
        vm.deal(user, 100 ether);
        vm.deal(buyer, 100 ether);

        token.mint(seller, 1, 10);
        vm.prank(seller);
        token.setApprovalForAll(address(market), true);
    }

    function newMarket(string memory uri, string memory name) internal returns (Marketplace made) {
        vm.prank(brokerKey);
        made = new Marketplace(1, uri, name);
    }

    function test_MarketplaceKeysGoToTheDeployer() public {
        assertEq(market.balanceOf(brokerKey, market.handlerToken()), 2);
        assertEq(market.balanceOf(address(ledger), market.handlerToken()), 0);
    }

    function test_AccountsCanBeFoundByNameOrNumber() public {
        (string memory name, address found, bool exist) = ledger.checkAccount("alice", 0);
        assertEq(name, "alice");
        assertEq(found, address(portfolio));
        assertTrue(exist);

        (name, found, exist) = ledger.checkAccount("", 1);
        assertEq(found, address(portfolio));

        (name, found, exist) = ledger.checkAccount("nobody", 99);
        assertFalse(exist);
        assertEq(found, address(0));
    }

    function test_LookingUpAnAccountDoesNotCreateIt() public {
        ledger.checkAccount("nobody", 0);
        vm.prank(user);
        (, address made) = ledger.createAccount("nobody");
        assertTrue(made != address(0));
    }

    function test_AccountNamesAreUnique() public {
        vm.startPrank(user);
        vm.expectRevert("account already exist");
        ledger.createAccount("alice");
        vm.expectRevert("Account name cannot be empty");
        ledger.createAccount("");
        vm.stopPrank();
    }

    function test_FundsCanBeSentByName() public {
        vm.prank(friend);
        (, address friendsPortfolio) = ledger.createAccount("friend");
        vm.prank(user);
        portfolio.sendFunds{value: 1 ether}("friend");
        assertEq(friendsPortfolio.balance, 1 ether);

        vm.prank(user);
        vm.expectRevert("User does not exist");
        portfolio.sendFunds{value: 1 ether}("nobody");
    }

    function test_PortfolioBuysAndHoldsTokens() public {
        vm.prank(seller);
        market.createList(address(token), 1, 2, 2 hours, 1 ether);
        vm.prank(user);
        portfolio.buyListToken{value: 1.5 ether}(0);
        assertEq(token.balanceOf(address(portfolio), 1), 2);
        assertEq(address(portfolio).balance, 0.5 ether);

        vm.prank(user);
        portfolio.withdrawFunds(user, 0.5 ether);
        assertEq(user.balance, 99 ether);
    }

    function test_PortfolioSellsAndCollects() public {
        token.mint(address(portfolio), 1, 3);
        vm.startPrank(user);
        portfolio.approveMarketplace(address(token), true);
        portfolio.createList(address(token), 1, 3, 2 hours, 1 ether);
        vm.stopPrank();

        vm.prank(buyer);
        market.buyListToken{value: 1 ether}(0);
        assertEq(token.balanceOf(buyer, 1), 3);
        assertEq(market.escrowAmount(address(portfolio)), 0.95 ether);

        vm.prank(user);
        portfolio.withdrawEscrow(0.95 ether);
        assertEq(address(portfolio).balance, 0.95 ether);
    }

    function test_PortfolioDepositsIntoEscrowInsteadOfWithdrawing() public {
        vm.prank(user);
        portfolio.depositEscrow{value: 2 ether}(2 ether);
        assertEq(market.escrowAmount(address(portfolio)), 2 ether);
    }

    function test_PortfolioOffersWithRealMoney() public {
        vm.prank(seller);
        market.createList(address(token), 1, 2, 2 hours, 1 ether);
        vm.prank(user);
        portfolio.makeOffer{value: 0.5 ether}(0, 0.5 ether);
        assertEq(market.lockedEscrow(address(portfolio)), 0.5 ether);

        vm.prank(user);
        portfolio.cancelOffer(0, 0);
        assertEq(address(portfolio).balance, 0.5 ether);
    }

    function test_PortfolioAcceptsAnOffer() public {
        token.mint(address(portfolio), 1, 1);
        vm.startPrank(user);
        portfolio.approveMarketplace(address(token), true);
        portfolio.createList(address(token), 1, 1, 2 hours, 1 ether);
        vm.stopPrank();
        vm.prank(buyer);
        market.makeOffer{value: 0.5 ether}(0, 0.5 ether);
        vm.prank(user);
        portfolio.acceptOffer(0, 0);
        assertEq(token.balanceOf(buyer, 1), 1);
    }

    function test_PortfolioBidsWithRealMoneyAndClaims() public {
        uint start = block.timestamp + 1;
        vm.prank(seller);
        market.createAuction(address(token), 1, 2, 1 ether, 0.1 ether, start, 2 days, false);
        vm.warp(start);
        vm.prank(user);
        portfolio.placeBid{value: 1 ether}(0);
        vm.warp(start + 2 days + 1);
        vm.prank(user);
        assertTrue(portfolio.claimAuction(0));
        assertEq(token.balanceOf(address(portfolio), 1), 2);
    }

    function test_PortfolioCreatesAndCancelsAuctionsAndLists() public {
        token.mint(address(portfolio), 1, 1);
        uint start = block.timestamp + 1;
        vm.startPrank(user);
        portfolio.createAuction(address(token), 1, 1, 1 ether, 1, start, 2 days, false);
        portfolio.createList(address(token), 1, 1, 2 hours, 1 ether);
        portfolio.cancelList(0);
        vm.warp(start + 2 days + 1);
        portfolio.cancelAuction(0);
        vm.stopPrank();
    }

    function test_PortfolioTransfers() public {
        token.mint(address(portfolio), 1, 1);
        vm.startPrank(user);
        portfolio.approveMarketplace(address(token), true);
        portfolio.transfer(friend, address(token), 1, 1);
        vm.stopPrank();
        assertEq(token.balanceOf(friend, 1), 1);
    }

    function test_BrokerResetsTheOwner() public {
        uint key = portfolio.handlerToken();
        vm.prank(brokerKey);
        portfolio.resetOwner(friend);
        assertEq(portfolio.balanceOf(friend, key), 1);
        assertEq(portfolio.balanceOf(user, key), 0);
        assertEq(portfolio.currentOwner(), friend);

        vm.prank(user);
        vm.expectRevert("broker does not hold handler token");
        portfolio.resetOwner(user);
    }

    function test_BrokerCanStillResetAfterTheKeyMoved() public {
        uint key = portfolio.handlerToken();
        vm.prank(user);
        portfolio.safeTransferFrom(user, friend, key, 1, "");
        assertEq(portfolio.currentOwner(), friend);
        vm.prank(brokerKey);
        portfolio.resetOwner(user);
        assertEq(portfolio.balanceOf(friend, key), 0);
        assertEq(portfolio.balanceOf(user, key), 1);
    }

    function test_SavedMarketplacesKeepTheirOwnNames() public {
        Marketplace other = newMarket("other", "Other Market");
        vm.startPrank(user);
        portfolio.saveMarketplace(address(other));
        (address saved, string memory name,) = portfolio.viewSavedMarketPlaces(1);
        vm.stopPrank();
        assertEq(saved, address(other));
        assertEq(name, "Other Market");
    }

    function test_DeletingAMarketplaceKeepsTheOthersInPlace() public {
        Marketplace second = newMarket("b", "B");
        Marketplace third = newMarket("c", "C");
        vm.startPrank(user);
        portfolio.saveMarketplace(address(second));
        portfolio.saveMarketplace(address(third));
        portfolio.deleteMarketplace(1);
        vm.expectRevert("Marketplace was already removed");
        portfolio.deleteMarketplace(1);
        vm.expectRevert("Marketplace is in use");
        portfolio.deleteMarketplace(0);
        vm.expectRevert("Marketplace index out of range");
        portfolio.deleteMarketplace(9);
        (address saved,,) = portfolio.viewSavedMarketPlaces(2);
        assertEq(saved, address(third));
        portfolio.saveMarketplace(address(second));
        vm.stopPrank();
        assertEq(portfolio.marketplaceCount(), 4);
    }

    function test_ChangingMarketplaceSavesIt() public {
        Marketplace other = newMarket("other", "Other Market");
        vm.prank(user);
        portfolio.changeMarketplace(other);
        assertEq(address(portfolio.marketplace()), address(other));
        assertEq(portfolio.marketplaceCount(), 2);
    }

    function test_OnlyTheOwnerActs() public {
        vm.startPrank(friend);
        vm.expectRevert("user does not hold handler token");
        portfolio.withdrawFunds(friend, 0);
        vm.expectRevert("user does not hold handler token");
        portfolio.approveMarketplace(address(token), true);
        vm.expectRevert("user does not hold handler token");
        portfolio.createList(address(token), 1, 1, 2 hours, 1);
        vm.expectRevert("user does not hold handler token");
        portfolio.withdrawEscrow(0);
        vm.expectRevert("user does not hold handler token");
        portfolio.changeMarketplace(market);
        vm.stopPrank();
    }
}

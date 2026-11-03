// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./Mocks.sol";
import "../../contracts/Defi-Tools/Forward.sol";
import "../../contracts/Defi-Tools/Future.sol";
import "../../contracts/Defi-Tools/MultiAssetBatch.sol";

contract ForwardTest is Test {
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    MockToken token;
    Forward forward;
    uint date;

    function setUp() public {
        token = new MockToken();
        token.mint(seller, 7, 1);
        date = block.timestamp + 30 days;
        vm.startPrank(seller);
        forward = new Forward("uri");
        token.setApprovalForAll(address(forward), true);
        vm.stopPrank();
        vm.deal(buyer, 10 ether);
    }

    function list() internal {
        vm.prank(seller);
        forward.deployAssets(address(token), 7, date, 1 ether);
    }

    function test_ListingEscrowsTheAsset() public {
        list();
        assertEq(token.balanceOf(address(forward), 7), 1);
        assertTrue(forward.activated());
    }

    function test_FullSaleAndRedeem() public {
        list();
        vm.prank(buyer);
        forward.buyForwardsToken{value: 1.5 ether}(address(token), 7, date, 1 ether);
        assertEq(buyer.balance, 9 ether);
        assertTrue(forward.contractSold());

        vm.prank(buyer);
        vm.expectRevert("the date of maturity has not passed");
        forward.redeemForward();

        vm.warp(date);
        vm.prank(buyer);
        forward.redeemForward();
        assertEq(token.balanceOf(buyer, 7), 1);
        assertEq(forward.balanceOf(buyer, 0), 0);

        vm.prank(seller);
        forward.redeemContractValue();
        assertEq(seller.balance, 1 ether);
    }

    function test_ForwardRedeemsOnlyOnce() public {
        list();
        vm.prank(buyer);
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        vm.warp(date);
        vm.startPrank(buyer);
        forward.redeemForward();
        vm.expectRevert("you currently do not have custody of this contracts token");
        forward.redeemForward();
        vm.stopPrank();
    }

    function test_ForwardCannotBeTransferred() public {
        list();
        vm.prank(buyer);
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        vm.prank(buyer);
        vm.expectRevert("forwards are non-transferable");
        forward.safeTransferFrom(buyer, seller, 0, 1, "");
    }

    function test_TermsCannotChangeOnceListed() public {
        list();
        vm.prank(seller);
        vm.expectRevert("contract has already been activated");
        forward.deployAssets(address(token), 7, date + 1, 2 ether);
        vm.prank(buyer);
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        vm.prank(seller);
        vm.expectRevert("contract has been sold");
        forward.deployAssets(address(token), 7, date + 1, 2 ether);
    }

    function test_UnsoldAssetCanBeTakenBack() public {
        list();
        vm.prank(seller);
        forward.cancelListing();
        assertEq(token.balanceOf(seller, 7), 1);
        vm.prank(buyer);
        vm.expectRevert("contract has not been activated");
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
    }

    function test_APendingPurchaseFailsIfTheListingChanges() public {
        list();
        MockToken worthless = new MockToken();
        worthless.mint(seller, 1, 1);
        vm.startPrank(seller);
        forward.cancelListing();
        worthless.setApprovalForAll(address(forward), true);
        forward.deployAssets(address(worthless), 1, date, 1 ether);
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert("the terms have changed");
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        assertEq(buyer.balance, 10 ether);
    }

    function test_EachTermIsChecked() public {
        list();
        vm.startPrank(buyer);
        vm.expectRevert("the terms have changed");
        forward.buyForwardsToken{value: 1 ether}(address(1), 7, date, 1 ether);
        vm.expectRevert("the terms have changed");
        forward.buyForwardsToken{value: 1 ether}(address(token), 8, date, 1 ether);
        vm.expectRevert("the terms have changed");
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date + 1, 1 ether);
        vm.expectRevert("the terms have changed");
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 2 ether);
        vm.stopPrank();
    }

    function test_CannotBuyAfterMaturity() public {
        list();
        vm.warp(date);
        vm.prank(buyer);
        vm.expectRevert("the date of maturity has passed");
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
    }

    function test_SoldAssetCannotBeTakenBack() public {
        list();
        vm.prank(buyer);
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        vm.prank(seller);
        vm.expectRevert("contract has been sold");
        forward.cancelListing();
    }

    function test_BuyChecksThePriceAndSoldOnce() public {
        list();
        vm.startPrank(buyer);
        vm.expectRevert("funds not enough to purchase contract");
        forward.buyForwardsToken{value: 0.5 ether}(address(token), 7, date, 1 ether);
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        vm.expectRevert("contract has been sold");
        forward.buyForwardsToken{value: 1 ether}(address(token), 7, date, 1 ether);
        vm.stopPrank();
    }

    function test_OnlyTheHandlerRuns() public {
        vm.startPrank(buyer);
        vm.expectRevert("you are currently not the handeler of this contract");
        forward.deployAssets(address(token), 7, date, 1 ether);
        vm.expectRevert("you are currently not the handeler of this contract");
        forward.redeemContractValue();
        vm.expectRevert("you are currently not the handeler of this contract");
        forward.cancelListing();
        vm.stopPrank();
    }

    function test_RefusesStrayTokens() public {
        token.mint(buyer, 9, 1);
        vm.prank(buyer);
        vm.expectRevert();
        token.safeTransferFrom(buyer, address(forward), 9, 1, "");
    }
}

contract FutureTest is Test {
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    address stranger = makeAddr("stranger");
    MockToken token;
    Future future;
    uint date;
    uint constant WINDOW = 1 days;

    function setUp() public {
        token = new MockToken();
        token.mint(seller, 1, 1);
        token.mint(seller, 2, 1);
        date = block.timestamp + 30 days;
        uint[] memory ids = new uint[](2);
        ids[0] = 1;
        ids[1] = 2;
        vm.startPrank(seller);
        // Deposit is 10% of the price and the fee is 1%
        future = new Future(address(token), ids, 10, 10, "uri", WINDOW);
        token.setApprovalForAll(address(future), true);
        vm.stopPrank();
        vm.deal(buyer, 100 ether);
    }

    function list() internal {
        vm.prank(seller);
        future.listSale(date, 10 ether);
    }

    function buy() internal {
        list();
        vm.prank(buyer);
        future.initiateContract{value: 1.1 ether}(date, 10 ether);
    }

    function test_ConstructorChecksItsInput() public {
        uint[] memory ids = new uint[](1);
        vm.expectRevert("Tokens are required");
        new Future(address(token), new uint[](0), 10, 10, "uri", WINDOW);
        vm.expectRevert("Deposit divisor must be greater than 0");
        new Future(address(token), ids, 0, 10, "uri", WINDOW);
        vm.expectRevert("Fee cannot be above 100%");
        new Future(address(token), ids, 10, 1001, "uri", WINDOW);
        vm.expectRevert("Redemption time limit must be greater than 0");
        new Future(address(token), ids, 10, 10, "uri", 0);
    }

    function test_ListingSetsTermsAndEscrowsAssets() public {
        list();
        assertEq(future.Deposit(), 1 ether);
        assertEq(future.currentFee(), 0.1 ether);
        assertEq(token.balanceOf(address(future), 1), 1);
        assertEq(token.balanceOf(address(future), 2), 1);
    }

    function test_HandlerAndFutureTokensAreDifferent() public {
        assertTrue(future.handelerToken() != future.futureToken());
        assertEq(future.balanceOf(seller, future.futureToken()), 0);
        list();
        vm.warp(date);
        vm.prank(seller);
        vm.expectRevert("you currently do not have custody of this contracts token");
        future.BuyAsset{value: 0}();
    }

    function test_FullSaleCompletes() public {
        buy();
        assertEq(future.balanceOf(buyer, 0), 1);
        assertEq(buyer.balance, 98.9 ether);

        vm.warp(date);
        vm.prank(buyer);
        future.BuyAsset{value: 11 ether}();

        // Paid the fee and the price, and got back the deposit and the change
        assertEq(buyer.balance, 100 ether - 0.1 ether - 10 ether);
        assertEq(token.balanceOf(buyer, 1), 1);
        assertEq(token.balanceOf(buyer, 2), 1);
        assertEq(future.checkContractStatus(), "Contract is Completed");

        vm.prank(seller);
        future.redeemDeposit();
        assertEq(seller.balance, 10.1 ether);
        assertEq(address(future).balance, 0);
    }

    function test_InitiateRefundsChange() public {
        list();
        vm.prank(buyer);
        future.initiateContract{value: 5 ether}(date, 10 ether);
        assertEq(buyer.balance, 98.9 ether);
    }

    function test_BuyAssetOnlyInsideTheWindow() public {
        buy();
        vm.startPrank(buyer);
        vm.expectRevert("the date of maturity has not passed");
        future.BuyAsset{value: 10 ether}();

        vm.warp(date + WINDOW + 1);
        vm.expectRevert("Contract in Default");
        future.BuyAsset{value: 10 ether}();
        vm.stopPrank();
    }

    function test_BuyAssetNeedsThePrice() public {
        buy();
        vm.warp(date);
        vm.prank(buyer);
        vm.expectRevert("not enough funds");
        future.BuyAsset{value: 9 ether}();
    }

    function test_HandlerGetsOnlyTheFeeBeforeTheEnd() public {
        buy();
        vm.prank(seller);
        future.redeemDeposit();
        assertEq(seller.balance, 0.1 ether);
        assertEq(address(future).balance, 1 ether);
        vm.prank(seller);
        vm.expectRevert("Nothing to redeem");
        future.redeemDeposit();
    }

    function test_DefaultGivesTheHandlerTheDepositAndAssets() public {
        buy();
        vm.warp(date + WINDOW + 1);
        assertEq(future.checkContractStatus(), "Contract is in Default");
        vm.prank(seller);
        future.redeemDeposit();
        assertEq(seller.balance, 1.1 ether);
        assertEq(token.balanceOf(seller, 1), 1);
        assertEq(address(future).balance, 0);

        vm.prank(seller);
        vm.expectRevert("Nothing to redeem");
        future.redeemDeposit();
    }

    function test_StatusBeforeTheEndIsPending() public {
        assertEq(future.checkContractStatus(), "Contract Currently Pending");
        buy();
        assertEq(future.checkContractStatus(), "Contract Currently Pending");
    }

    function test_FutureTokenCanBeTransferred() public {
        buy();
        vm.prank(buyer);
        future.safeTransferFrom(buyer, stranger, 0, 1, "");
        vm.deal(stranger, 10 ether);
        vm.warp(date);
        vm.prank(stranger);
        future.BuyAsset{value: 10 ether}();
        assertEq(token.balanceOf(stranger, 1), 1);
        assertEq(stranger.balance, 1 ether);
    }

    function test_TermsCanChangeOnlyBeforeASale() public {
        list();
        vm.prank(seller);
        future.listSale(date, 20 ether);
        assertEq(future.Deposit(), 2 ether);
        assertEq(token.balanceOf(address(future), 1), 1);

        vm.prank(buyer);
        future.initiateContract{value: 2.2 ether}(date, 20 ether);
        vm.prank(seller);
        vm.expectRevert("contract has been sold");
        future.listSale(date, 1 ether);
    }

    function test_APendingPurchaseFailsIfTheTermsChange() public {
        list();
        vm.prank(seller);
        future.listSale(block.timestamp + 1, 10 ether);
        vm.prank(buyer);
        vm.expectRevert("the terms have changed");
        future.initiateContract{value: 1.1 ether}(date, 10 ether);

        vm.prank(seller);
        future.listSale(date, 20 ether);
        vm.prank(buyer);
        vm.expectRevert("the terms have changed");
        future.initiateContract{value: 2.2 ether}(date, 10 ether);
    }

    function test_UnsoldAssetsCanBeTakenBack() public {
        list();
        vm.prank(seller);
        future.cancelSale();
        assertEq(token.balanceOf(seller, 1), 1);
        vm.prank(buyer);
        vm.expectRevert("contract is not listed");
        future.initiateContract{value: 1.1 ether}(date, 10 ether);
    }

    function test_CannotBuyAfterTheDate() public {
        list();
        vm.warp(date);
        vm.prank(buyer);
        vm.expectRevert("the date of maturity has passed");
        future.initiateContract{value: 1.1 ether}(date, 10 ether);
    }

    function test_OnlyTheHandlerRuns() public {
        vm.startPrank(stranger);
        vm.expectRevert("you are currently not the handler of this contract");
        future.listSale(date, 1 ether);
        vm.expectRevert("you are currently not the handler of this contract");
        future.cancelSale();
        vm.expectRevert("you are currently not the handler of this contract");
        future.redeemDeposit();
        vm.stopPrank();
    }

    function testFuzz_MoneyInEqualsMoneyOut(uint96 price, uint8 divisor, uint16 feeRate, bool completes) public {
        uint divisable = bound(divisor, 1, 100);
        uint rate = bound(feeRate, 0, 1000);
        uint total = bound(price, divisable, 1000 ether);
        uint[] memory ids = new uint[](1);
        ids[0] = 3;
        token.mint(seller, 3, 1);
        vm.startPrank(seller);
        Future f = new Future(address(token), ids, divisable, rate, "uri", WINDOW);
        token.setApprovalForAll(address(f), true);
        f.listSale(date, total);
        vm.stopPrank();

        uint deposit = f.Deposit();
        uint feeAmount = f.currentFee();
        vm.deal(buyer, deposit + feeAmount + total);
        uint start = buyer.balance;
        vm.prank(buyer);
        f.initiateContract{value: deposit + feeAmount}(date, total);
        assertEq(address(f).balance, deposit + feeAmount);

        vm.warp(completes ? date : date + WINDOW + 1);
        if (completes) {
            vm.prank(buyer);
            f.BuyAsset{value: total}();
        }
        vm.prank(seller);
        f.redeemDeposit();

        assertEq(address(f).balance, 0);
        assertEq(buyer.balance + seller.balance, start);
    }
}

contract MultiAssetBatchTest is Test {
    address owner = makeAddr("owner");
    address stranger = makeAddr("stranger");
    MockToken tokenA;
    MockToken tokenB;
    MultiAssetBatch batch;

    function setUp() public {
        tokenA = new MockToken();
        tokenB = new MockToken();
        tokenA.mint(owner, 1, 10);
        tokenA.mint(owner, 2, 10);
        tokenB.mint(owner, 1, 10);
        vm.startPrank(owner);
        batch = new MultiAssetBatch(2, "uri", "Batch", 2);
        tokenA.setApprovalForAll(address(batch), true);
        tokenB.setApprovalForAll(address(batch), true);
        vm.stopPrank();
    }

    function one(uint value) internal pure returns (uint[] memory list) {
        list = new uint[](1);
        list[0] = value;
    }

    function test_OneAssetCanLeaveWhenAnotherIsStuck() public {
        PausableToken stuck = new PausableToken();
        stuck.mint(owner, 1, 1);
        vm.startPrank(owner);
        stuck.setApprovalForAll(address(batch), true);
        batch.addAssets(address(stuck), "Stuck", one(1), one(1));
        batch.addAssets(address(tokenA), "A", one(1), one(5));
        vm.stopPrank();
        stuck.setPaused(true);

        vm.startPrank(owner);
        vm.expectRevert("paused");
        batch.redeemAssets();
        batch.redeemAsset(1);
        assertEq(tokenA.balanceOf(owner, 1), 10);
        vm.expectRevert("No asset at that index");
        batch.redeemAsset(1);
        vm.stopPrank();

        stuck.setPaused(false);
        vm.prank(owner);
        batch.redeemAssets();
        assertEq(stuck.balanceOf(owner, 1), 1);
        assertEq(batch.tokenIDNumber(), 0);
    }

    function test_RedeemingOneAssetNeedsAKey() public {
        vm.startPrank(owner);
        batch.addAssets(address(tokenA), "A", one(1), one(5));
        vm.stopPrank();
        vm.prank(stranger);
        vm.expectRevert("user does not hold handler token");
        batch.redeemAsset(0);
    }

    function test_AddsANewAsset() public {
        vm.prank(owner);
        (string memory message, bool ok) = batch.addAssets(address(tokenA), "A", one(1), one(3));
        assertTrue(ok);
        assertEq(message, "new asset added");
        assertEq(tokenA.balanceOf(address(batch), 1), 3);
        (address contractAddress, string memory name, uint[] memory amounts,,, bool exist) = batch.viewAssets(0);
        assertEq(contractAddress, address(tokenA));
        assertEq(name, "A");
        assertEq(amounts[0], 3);
        assertTrue(exist);
    }

    function test_AddsMoreToAnExistingAsset() public {
        vm.startPrank(owner);
        batch.addAssets(address(tokenA), "A", one(1), one(3));
        (string memory message,) = batch.addAssets(address(tokenA), "A", one(2), one(4));
        vm.stopPrank();
        assertEq(message, "Assets Added");
        assertEq(batch.tokenIDNumber(), 1);
        assertEq(tokenA.balanceOf(address(batch), 2), 4);
    }

    function test_BatchLimitIsExact() public {
        MockToken tokenC = new MockToken();
        vm.startPrank(owner);
        batch.addAssets(address(tokenA), "A", one(1), one(1));
        batch.addAssets(address(tokenB), "B", one(1), one(1));
        vm.expectRevert("Contract has hit Max Batch limit");
        batch.addAssets(address(tokenC), "C", one(1), one(1));
        // More tokens from a contract it already holds still fit
        batch.addAssets(address(tokenA), "A", one(2), one(1));
        vm.stopPrank();
    }

    function test_RedeemReturnsEverythingOnce() public {
        vm.startPrank(owner);
        batch.addAssets(address(tokenA), "A", one(1), one(3));
        batch.addAssets(address(tokenA), "A", one(2), one(4));
        batch.addAssets(address(tokenB), "B", one(1), one(5));
        batch.redeemAssets();
        vm.stopPrank();
        assertEq(tokenA.balanceOf(owner, 1), 10);
        assertEq(tokenA.balanceOf(owner, 2), 10);
        assertEq(tokenB.balanceOf(owner, 1), 10);
        assertEq(batch.tokenIDNumber(), 0);
        (,,,,, bool exist) = batch.viewAssets(0);
        assertFalse(exist);

        vm.prank(owner);
        assertTrue(batch.redeemAssets());
        assertEq(tokenA.balanceOf(owner, 1), 10);
    }

    function test_EmptiedBatchCanBeFilledAgain() public {
        vm.startPrank(owner);
        batch.addAssets(address(tokenA), "A", one(1), one(3));
        batch.redeemAssets();
        batch.addAssets(address(tokenA), "A", one(2), one(2));
        batch.redeemAssets();
        vm.stopPrank();
        assertEq(tokenA.balanceOf(owner, 1), 10);
        assertEq(tokenA.balanceOf(owner, 2), 10);
    }

    function test_AddChecksItsInput() public {
        vm.startPrank(owner);
        vm.expectRevert("Contract address cannot be 0");
        batch.addAssets(address(0), "A", one(1), one(1));
        vm.expectRevert("Asset name cannot be empty");
        batch.addAssets(address(tokenA), "", one(1), one(1));
        vm.expectRevert("ID array cannot be empty");
        batch.addAssets(address(tokenA), "A", new uint[](0), one(1));
        vm.expectRevert("Both the token id and the amount arrays must have the same length");
        batch.addAssets(address(tokenA), "A", one(1), new uint[](2));
        vm.stopPrank();
    }

    function test_OnlyKeyHoldersAct() public {
        vm.startPrank(stranger);
        vm.expectRevert("user does not hold handler token");
        batch.addAssets(address(tokenA), "A", one(1), one(1));
        vm.expectRevert("user does not hold handler token");
        batch.redeemAssets();
        vm.stopPrank();
    }

    function test_RefusesStrayTokens() public {
        vm.prank(owner);
        vm.expectRevert();
        tokenA.safeTransferFrom(owner, address(batch), 1, 1, "");
        vm.prank(owner);
        vm.expectRevert();
        tokenA.safeBatchTransferFrom(owner, address(batch), one(1), one(1), "");
    }

    function testFuzz_TokensAreConserved(uint8 first, uint8 second) public {
        uint a = bound(first, 1, 10);
        uint b = bound(second, 1, 10);
        vm.startPrank(owner);
        batch.addAssets(address(tokenA), "A", one(1), one(a));
        batch.addAssets(address(tokenB), "B", one(1), one(b));
        assertEq(tokenA.balanceOf(owner, 1) + tokenA.balanceOf(address(batch), 1), 10);
        batch.redeemAssets();
        vm.stopPrank();
        assertEq(tokenA.balanceOf(owner, 1), 10);
        assertEq(tokenB.balanceOf(owner, 1), 10);
    }
}

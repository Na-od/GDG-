// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAuction.sol";

contract SimpleAuctionTest is Test {
    SimpleAuction auction;

    address seller = address(1);
    address bidder1 = address(2);
    address bidder2 = address(3);

    function setUp() public {
        vm.prank(seller);
        auction = new SimpleAuction();

        // Give ETH to bidders
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    function testCreateAuction() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        (
            address _seller,
            address highestBidder,
            uint256 highestBid,
            uint256 endTime,
            bool ended
        ) = auction.auctions(1);

        assertEq(_seller, seller);
        assertEq(highestBidder, address(0));
        assertEq(highestBid, 0);
        assertEq(ended, false);
        assertTrue(endTime > block.timestamp);
    }

    function testBidding() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        // bidder1 bids 1 ETH
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        (, address highestBidder, uint256 highestBid,,) = auction.auctions(1);

        assertEq(highestBidder, bidder1);
        assertEq(highestBid, 1 ether);
    }

    function testOutbidAndRefund() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        // First bid
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        // Second higher bid
        vm.prank(bidder2);
        auction.bid{value: 2 ether}(1);

        uint256 refund = auction.pendingReturns(bidder1);
        assertEq(refund, 1 ether);
    }

    function testWithdraw() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        vm.prank(bidder2);
        auction.bid{value: 2 ether}(1);

        uint256 balanceBefore = bidder1.balance;

        vm.prank(bidder1);
        auction.withdraw();

        uint256 balanceAfter = bidder1.balance;

        assertEq(balanceAfter, balanceBefore + 1 ether);
    }

    function testEndAuction() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        // Move time forward
        vm.warp(block.timestamp + 2 days);

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        auction.endAuction(1);

        uint256 sellerBalanceAfter = seller.balance;

        assertEq(sellerBalanceAfter, sellerBalanceBefore + 1 ether);
    }

    function testCannotBidAfterEnd() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        vm.warp(block.timestamp + 2 days);

        vm.prank(bidder1);
        vm.expectRevert("Auction ended");
        auction.bid{value: 1 ether}(1);
    }

    function testCannotEndTwice() public {
        vm.prank(seller);
        auction.createAuction(1 days);

        vm.warp(block.timestamp + 2 days);

        vm.prank(seller);
        auction.endAuction(1);

        vm.prank(seller);
        vm.expectRevert("Auction already ended");
        auction.endAuction(1);
    }
}
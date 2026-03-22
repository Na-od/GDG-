// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract SharedWalletTest is Test {
    SharedWallet public wallet;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        wallet = new SharedWallet();
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function test_DepositUpdatesUserAndTotalBalance() public {
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        assertEq(wallet.balances(user1), 1 ether);
        assertEq(wallet.totalBalance(), 1 ether);
    }

    function test_DepositStoresDepositRecord() public {
        vm.prank(user1);
        wallet.deposit{value: 2 ether}();

        (address user, uint256 amount, uint256 time) = wallet.deposits(0);
        assertEq(user, user1);
        assertEq(amount, 2 ether);
        assertGt(time, 0);
    }

    function test_RevertIfDepositIsZero() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        wallet.deposit{value: 0}();
    }

    function test_WithdrawByOwner() public {
        vm.prank(user1);
        wallet.deposit{value: 3 ether}();

        uint256 ownerBalanceBefore = address(this).balance;
        wallet.withdraw(1 ether);
        uint256 ownerBalanceAfter = address(this).balance;

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 1 ether);
        assertEq(wallet.totalBalance(), 2 ether);
    }

    function test_RevertIfNonOwnerWithdraws() public {
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        vm.prank(user2);
        vm.expectRevert("Only owner can withdraw");
        wallet.withdraw(1 ether);
    }

    function test_RevertIfWithdrawExceedsBalance() public {
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        vm.expectRevert("Insufficient contract balance");
        wallet.withdraw(2 ether);
    }
}

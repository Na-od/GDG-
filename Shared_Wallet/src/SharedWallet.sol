// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SharedWallet {
    struct Deposit {
        address user;
        uint256 amount;
        uint256 time;
    }

    address public owner;
    uint256 public totalBalance;
    mapping(address => uint256) public balances;
    Deposit[] public deposits;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        deposits.push(Deposit({user: msg.sender, amount: msg.value, time: block.timestamp}));
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        require(amount <= totalBalance, "Insufficient tracked balance");

        totalBalance -= amount;
        payable(owner).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

      // STATE VARIABLES

contract StudentSavingsWallet {
    
    mapping(address => uint256) private userBalances;
   
    mapping(address => Transaction[]) private userTransactions;
    address public owner;
    uint256 public constant MINIMUM_DEPOSIT = 0.001 ether;
    uint256 public constant WITHDRAWAL_TIMELOCK = 24 hours;
    mapping(address => uint256) private lastDepositTime;
    uint256 public totalContractBalance;
   
     // STRUCTS & ENUMS

    enum TransactionType { DEPOSIT, WITHDRAWAL }
    
    struct Transaction {
        TransactionType txType;
        uint256 amount;
        uint256 timestamp;
        uint256 balanceAfter;
    }
    
     // EVENTS

    event Deposit(address indexed user, uint256 amount, uint256 newBalance, uint256 timestamp);
    
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance, uint256 timestamp);
   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
      
    // MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier meetsMinimumDeposit() {
        require(msg.value >= MINIMUM_DEPOSIT, "Deposit amount is below minimum requirement");
        _;
    }
    
    modifier timeLockPassed() {
        require(
            block.timestamp >= lastDepositTime[msg.sender] + WITHDRAWAL_TIMELOCK,
            "Withdrawal time-lock period has not passed yet"
        );
        _;
    }
    
    // CONSTRUCTOR
    
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
    
    
    // CORE FUNCTIONS
    
    function deposit() public payable meetsMinimumDeposit {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        
        // Update user balance
        userBalances[msg.sender] += msg.value;
        totalContractBalance += msg.value;
        
        // Update last deposit time for time-lock
        lastDepositTime[msg.sender] = block.timestamp;
        
        // Record transaction
        userTransactions[msg.sender].push(Transaction({
            txType: TransactionType.DEPOSIT,
            amount: msg.value,
            timestamp: block.timestamp,
            balanceAfter: userBalances[msg.sender]
        }));
        
        // Emit deposit event
        emit Deposit(msg.sender, msg.value, userBalances[msg.sender], block.timestamp);
    }
    
    function withdraw(uint256 _amount) public timeLockPassed {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        
        // Update user balance before transfer (Checks-Effects-Interactions pattern)
        userBalances[msg.sender] -= _amount;
        totalContractBalance -= _amount;
        
        // Record transaction
        userTransactions[msg.sender].push(Transaction({
            txType: TransactionType.WITHDRAWAL,
            amount: _amount,
            timestamp: block.timestamp,
            balanceAfter: userBalances[msg.sender]
        }));
        
        // Emit withdrawal event
        emit Withdrawal(msg.sender, _amount, userBalances[msg.sender], block.timestamp);
        
        // Transfer ETH to user
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
    }
    
   
    function emergencyWithdraw(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        
        userBalances[msg.sender] -= _amount;
        totalContractBalance -= _amount;
        
        userTransactions[msg.sender].push(Transaction({
            txType: TransactionType.WITHDRAWAL,
            amount: _amount,
            timestamp: block.timestamp,
            balanceAfter: userBalances[msg.sender]
        }));
        
        emit Withdrawal(msg.sender, _amount, userBalances[msg.sender], block.timestamp);
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Emergency transfer failed");
    }
    
    // VIEW FUNCTIONS
   
    function getMyBalance() public view returns (uint256) {
        return userBalances[msg.sender];
    }
    
    function getUserBalance(address _user) public view onlyOwner returns (uint256) {
        return userBalances[_user];
    }
    
    function getMyTransactionHistory() public view returns (Transaction[] memory) {
        return userTransactions[msg.sender];
    }
    
    function getUserTransactionHistory(address _user) public view onlyOwner returns (Transaction[] memory) {
        return userTransactions[_user];
    }
    

    function getTransactionCount() public view returns (uint256) {
        return userTransactions[msg.sender].length;
    }
    
    function getTimeLockRemaining() public view returns (uint256) {
        uint256 unlockTime = lastDepositTime[msg.sender] + WITHDRAWAL_TIMELOCK;
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
    
    function getWithdrawalUnlockTime() public view returns (uint256) {
        return lastDepositTime[msg.sender] + WITHDRAWAL_TIMELOCK;
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    
    // ADMIN FUNCTIONS
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
   
    // FALLBACK & RECEIVE
    
    receive() external payable {
        require(msg.value >= MINIMUM_DEPOSIT, "Direct transfers must meet minimum deposit");
        
        userBalances[msg.sender] += msg.value;
        totalContractBalance += msg.value;
        lastDepositTime[msg.sender] = block.timestamp;
        
        userTransactions[msg.sender].push(Transaction({
            txType: TransactionType.DEPOSIT,
            amount: msg.value,
            timestamp: block.timestamp,
            balanceAfter: userBalances[msg.sender]
        }));
        
        emit Deposit(msg.sender, msg.value, userBalances[msg.sender], block.timestamp);
    }
    
    
    fallback() external payable {
        revert("Function does not exist");
    }
}

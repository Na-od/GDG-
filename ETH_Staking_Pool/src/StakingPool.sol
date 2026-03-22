// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakingPool {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

    address public owner;
    uint256 public rewardRate; // reward per second
    mapping(address => Stake) public stakes;

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    receive() external payable {}

    function stake() external payable {
        require(msg.value > 0, "Stake must be greater than 0");

        Stake storage userStake = stakes[msg.sender];
        require(
            userStake.amount == 0 || userStake.claimed,
            "Active stake already exists"
        );

        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            claimed: false
        });
    }

    function calculateReward(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        if (userStake.amount == 0 || userStake.claimed) {
            return 0;
        }

        uint256 duration = block.timestamp - userStake.startTime;
        return duration * rewardRate;
    }

    function unstake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");
        require(!userStake.claimed, "Stake already claimed");

        uint256 principal = userStake.amount;
        uint256 reward = calculateReward(msg.sender);
        uint256 payout = principal + reward;

        userStake.claimed = true;
        userStake.amount = 0;

        (bool sent, ) = payable(msg.sender).call{value: payout}("");
        require(sent, "ETH transfer failed");
    }
}

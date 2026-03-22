// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StakingPool} from "../src/StakingPool.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;

    address public alice = address(0xA11CE);
    uint256 public constant REWARD_RATE = 1 wei; // per second
    uint256 public constant STAKE_AMOUNT = 1 ether;

    function setUp() public {
        stakingPool = new StakingPool(REWARD_RATE);
        vm.deal(alice, 10 ether);
    }

    function test_ConstructorSetsOwnerAndRewardRate() public {
        assertEq(stakingPool.owner(), address(this));
        assertEq(stakingPool.rewardRate(), REWARD_RATE);
    }

    function test_StakeStoresData() public {
        vm.prank(alice);
        stakingPool.stake{value: STAKE_AMOUNT}();

        (uint256 amount, uint256 startTime, bool claimed) = stakingPool.stakes(
            alice
        );

        assertEq(amount, STAKE_AMOUNT);
        assertEq(startTime, block.timestamp);
        assertEq(claimed, false);
    }

    function test_StakeRevertsWhenZeroValue() public {
        vm.prank(alice);
        vm.expectRevert("Stake must be greater than 0");
        stakingPool.stake{value: 0}();
    }

    function test_CalculateRewardAfterTimePasses() public {
        vm.prank(alice);
        stakingPool.stake{value: STAKE_AMOUNT}();

        vm.warp(block.timestamp + 100);
        uint256 reward = stakingPool.calculateReward(alice);

        assertEq(reward, 100 * REWARD_RATE);
    }

    function test_UnstakeTransfersStakeAndReward() public {
        vm.prank(alice);
        stakingPool.stake{value: STAKE_AMOUNT}();

        // Fund extra ETH so the pool can pay rewards.
        vm.deal(address(this), 5 ether);
        (bool funded, ) = payable(address(stakingPool)).call{value: 1 ether}("");
        require(funded, "Funding failed");

        vm.warp(block.timestamp + 100);

        uint256 balanceBefore = alice.balance;
        uint256 expectedReward = 100 * REWARD_RATE;

        vm.prank(alice);
        stakingPool.unstake();

        assertEq(alice.balance, balanceBefore + STAKE_AMOUNT + expectedReward);

        (uint256 amount, , bool claimed) = stakingPool.stakes(alice);
        assertEq(amount, 0);
        assertEq(claimed, true);
    }

    function test_UnstakeRevertsWhenAlreadyClaimed() public {
        vm.prank(alice);
        stakingPool.stake{value: STAKE_AMOUNT}();

        vm.deal(address(this), 5 ether);
        (bool funded, ) = payable(address(stakingPool)).call{value: 1 ether}("");
        require(funded, "Funding failed");

        vm.prank(alice);
        stakingPool.unstake();

        vm.prank(alice);
        vm.expectRevert("No stake found");
        stakingPool.unstake();
    }
}

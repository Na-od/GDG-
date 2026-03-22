// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StakingPool} from "../src/StakingPool.sol";

contract StakingPoolScript is Script {
    StakingPool public stakingPool;

    function setUp() public {}

    function run() public {
        // Example default reward rate: 1 wei per second.
        uint256 rewardRate = 1 wei;

        vm.startBroadcast();
        stakingPool = new StakingPool(rewardRate);
        vm.stopBroadcast();
    }
}

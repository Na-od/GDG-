// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract SharedWalletScript is Script {
    SharedWallet public wallet;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        wallet = new SharedWallet();

        vm.stopBroadcast();
    }
}

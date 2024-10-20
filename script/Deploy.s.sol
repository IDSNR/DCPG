// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {DCPG} from "../src/DCPG.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployScript is Script {

    DCPG dcpg;
    HelperConfig helperConfig;

    function run() public returns (DCPG, HelperConfig) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getNetworkConfig();
        dcpg = new DCPG(config.priceFeedAddresses, config.nameOfSymbols, config.tokenAddresses);
        vm.stopBroadcast();
        return (
            dcpg,
            helperConfig
        );
    }
}
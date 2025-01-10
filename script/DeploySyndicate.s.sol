// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment script
// include setup of initial contracts
// will need to get into deploying the ERC6551 and Azimuth contracts onto my testnets if/when we get more complicated about the minting permissions

import {Script} from "@forge-std/Script.sol";
import {SyndicateTokenV1} from "../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../src/SyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../src/SyndicateRegistry.sol";

contract DeploySyndicate is Script {
    function setUp() public {}

    function run() external returns (SyndicateRegistry) {
        vm.startBroadcast();
        SyndicateRegistry syndicateRegistry = new SyndicateRegistry();
        vm.stopBroadcast();
        return syndicateRegistry;
    }
}

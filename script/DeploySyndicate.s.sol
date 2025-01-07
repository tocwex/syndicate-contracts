// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment script
// include setup of initial contracts
// might need to get into deploying the ERC6551 and Azimuth contracts onto my testnets if/when we get more complicated about the minting permissions

import {Script} from "@forge-std/Script.sol";
import {SyndicateTokenV1} from "../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../src/SyndicateDeployerV1.sol";

contract DeploySyndicate is Script {
    function setUp() public {}

    function run() external returns (SyndicateDeployerV1) {
        vm.startBroadcast();
        SyndicateDeployerV1 syndicateDeployerV1 = new SyndicateDeployerV1();
        vm.stopBroadcast();
        return syndicateDeployerV1;
    }
    // struct DeploymentParams {
    //     address owner;
    //     uint256 initialSupply;
    //     uint256 maxSupply;
    //     string name;
    //     string symbol;
    // }
    //
    // DeploymentParams params;
    //
    // function setUp() public {
    //     params = DeploymentParams({
    //         owner: msg.sender,
    //         initialSupply: 100 * 10 ** 18,
    //         maxSupply: 1000 * 10 ** 18,
    //         name: "Syndicate Token",
    //         symbol: "SYN"
    //     });
    // }
    //
    // function run() external returns (SyndicateToken) {
    //     vm.startBroadcast();
    //     SyndicateToken syndicateToken = new SyndicateToken(
    //         params.owner,
    //         params.initialSupply,
    //         params.maxSupply,
    //         params.name,
    //         params.symbol
    //     );
    //     vm.stopBroadcast();
    //     return syndicateToken;
    // }
}

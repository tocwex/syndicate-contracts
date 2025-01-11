// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment script
// include setup of initial contracts
// will need to get into deploying the ERC6551 and Azimuth contracts onto my testnets if/when we get more complicated about the minting permissions

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {SyndicateTokenV1} from "../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../src/SyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../src/SyndicateRegistry.sol";

contract DeploySyndicate is Script {
    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    address public owner;

    function setUp() public {
        owner = vm.envAddress("PUBLIC_KEY_0");
    }

    function run() external returns (SyndicateRegistry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_0");

        vm.startBroadcast(deployerPrivateKey);

        registry = new SyndicateRegistry();
        deployerV1 = new SyndicateDeployerV1();

        vm.stopBroadcast();

        console.log("Registry Deployed to: ", address(registry));
        console.log("DeployerV1 deployed to: ", address(deployerV1));

        return registry;
    }
}

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment script
// include setup of initial contracts
// will need to get into deploying the ERC6551 and Azimuth contracts onto my testnets if/when we get more complicated about the minting permissions

import {Script} from "@forge-std/Script.sol";
import {console2} from "@forge-std/console2.sol";
import {SyndicateTokenV1} from "../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../src/SyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../src/SyndicateRegistry.sol";
import {ISyndicateRegistry} from "../src/interfaces/ISyndicateRegistry.sol";

contract DeploySyndicate is Script {
    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    SyndicateTokenV1 public syndicateToken;
    address public tocwexOwner;
    uint256 public fee; // starting point for deployer fee
    address public registryAddress;

    function setUp() public {
        tocwexOwner = vm.envAddress("PUBLIC_KEY_0");
    }

    function run() external {
        uint256 tocwexSyndicateSigner = vm.envUint("PRIVATE_KEY_0");

        vm.startBroadcast(tocwexSyndicateSigner);

        registry = new SyndicateRegistry();
        registryAddress = address(registry);
        deployerV1 = new SyndicateDeployerV1(registryAddress, fee);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        syndicateToken = SyndicateTokenV1(
            payable(
                deployerV1.deploySyndicate(
                    1000000000000000000000000, // initial supply to mint to owner
                    21000000000000000000000000, // immutable max supply of Token
                    256, // azimuth point of msg.sender (still needs validation check of some sort)
                    "Test Token", // token name
                    "TES" // token symbol
                )
            )
        );

        vm.stopBroadcast();

        console2.log("Registry Deployed to: ", address(registry));
        console2.log("DeployerV1 deployed to: ", address(deployerV1));
        console2.log(
            "Syndicate Token for: ",
            msg.sender,
            "deployed to: ",
            address(syndicateToken)
        );
    }
}

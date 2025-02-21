// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

import {Script} from "@forge-std/Script.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import {SyndicateTokenV1} from "../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../src/SyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../src/SyndicateRegistry.sol";
import {ISyndicateRegistry} from "../src/interfaces/ISyndicateRegistry.sol";
import {DeployConfig} from "../script/DeployConfig.s.sol";

contract DeploySyndicate is Script {
    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    SyndicateTokenV1 public syndicateToken;

    address public tocwexOwner;
    address public registryAddress;
    address public deployerV1Address;
    address public azimuthAddress;
    address public eclipticAddress;

    DeployConfig public deployConfig;
    DeployConfig.NetworkConfig public config;

    function setUp() public {
        tocwexOwner = vm.envAddress("SEPOLIA_PUBLIC_KEY_0");
        deployConfig = new DeployConfig();
        config = deployConfig.getConfig();

        console2.log("Deploying with address: ", config.deploymentAddress);
        console2.log("Network Config:");
        console2.log("Azimuth contract address: ", config.azimuthContract);
        console2.log("Ecliptic contract address: ", config.eclipticContract);
        console2.log("- Deployer Fee:", config.deployerFee);
        console2.log("- Existing Registry:", config.existingRegistryAddress);
        console2.log("- Existing Deployer:", config.existingDeployerAddress);
        console2.log("- Azimuth Point:", config.azimuthPoint);
        console2.log("- Token Name:", config.tokenName);
        console2.log("- Token Symbol:", config.tokenSymbol);
        console2.log("- Initial Supply:", config.initialSupply);
        console2.log("- Max Supply:", config.maxSupply);
    }

    function run() external {
        if (config.signerType == DeployConfig.SignerType.ContractWallet) {
            revert("Contract Wallet Logic not yet implemented");
        } else if (config.signerType == DeployConfig.SignerType.PrivateKey) {
            uint256 deploymentPrivateKey;
            if (block.chainid == 11155111) {
                string memory rawKey = string.concat("0x", vm.envString("SEPOLIA_PRIVATE_KEY_0"));
                deploymentPrivateKey = vm.parseUint(rawKey);
            } else {
                string memory rawKey = string.concat("0x", vm.envString("ANVIL_PRIVATE_KEY_0"));
                deploymentPrivateKey = vm.parseUint(rawKey);
            }
            vm.startBroadcast(deploymentPrivateKey);
        } else {
            // For Ledger/Keystore/Interactive, let forge handle the signing
            vm.startBroadcast();
        }

        if (config.existingRegistryAddress == address(0)) {
            azimuthAddress = config.azimuthContract;
            registry = new SyndicateRegistry(azimuthAddress);
            registryAddress = address(registry);
            console2.log("Registry deployed with Azimuth param of: ", azimuthAddress);
        } else {
            registryAddress = config.existingRegistryAddress;
            registry = SyndicateRegistry(payable(registryAddress));
        }

        if (config.existingDeployerAddress == address(0)) {
            deployerV1 = new SyndicateDeployerV1(registryAddress, config.deployerFee);
            registry.registerDeployer(
                ISyndicateRegistry.SyndicateDeployerData({
                    deployerAddress: address(deployerV1),
                    deployerVersion: 1,
                    isActive: true
                })
            );
        } else {
            deployerV1 = SyndicateDeployerV1(payable(config.existingDeployerAddress));
            deployerV1Address = address(deployerV1);

            ISyndicateRegistry.SyndicateDeployerData memory deployerData = registry.getDeployerData(deployerV1Address);

            if (deployerData.deployerAddress != deployerV1Address) {
                registry.registerDeployer(
                    ISyndicateRegistry.SyndicateDeployerData({
                        deployerAddress: address(deployerV1),
                        deployerVersion: 1,
                        isActive: true
                    })
                );
            }
            address tbaImplementation = config.implementationAddress;
            deployerV1.addApprovedTbaImplementation(tbaImplementation);
        }

        vm.stopBroadcast();

        console2.log("Registry Deployed to: ", address(registry));
        console2.log("DeployerV1 deployed to: ", address(deployerV1));
    }
}

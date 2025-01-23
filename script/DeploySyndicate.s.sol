// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment script
// include setup of initial contracts
// will need to get into deploying the ERC6551 and Azimuth contracts onto my testnets if/when we get more complicated about the minting permissions

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

    DeployConfig public deployConfig;
    DeployConfig.NetworkConfig public config;

    function setUp() public {
        tocwexOwner = vm.envAddress("SEPOLIA_PUBLIC_KEY_0");
        deployConfig = new DeployConfig();
        config = deployConfig.getConfig();

        console2.log("Deploying with address: ", config.deploymentAddress);
        console2.log("Network Config:");
        console2.log("- Deployer Fee:", config.deployerFee);
        console2.log("- Existing Registry:", config.existingRegistryAddress);
        console2.log("- Existing Deployer:", config.existingDeployerAddress);
        console2.log("- Azimuth Point:", config.azimuthPoint);
        console2.log("- Token Name:", config.tokenName);
        console2.log("- Token Symbol:", config.tokenSymbol);
        console2.log("- Initial Supply:", config.initialSupply);
        console2.log("- Max Supply:", config.maxSupply);
    }

    //// TODO Function to generate the deployment data
    //// This function will then need to pass this data as calldata through the
    //// smart contract wallet that is being used for deployment purposes
    // function getDeploymentData() internal returns (bytes memory) {
    //     vm.startPrank(config.deploymentAddress);
    //
    //     bytes memory registryData = abi.encodePacked(type(SyndicateRegistry).creationCode);
    //     bytes memory deployerData = abi.encodePacked(
    //         type(SyndicateDeployerV1).creationCode,
    //         abi.encode(address(0), config.deployerFee) // constructor args
    //     );
    //
    //// FIXME Doesn't currently generate the token data, in the event that
    //// we want to generate the initial token deployment here as well.
    //     vm.stopPrank();
    //
    //     return abi.encodePacked(registryData, deployerData);
    // }
    //
    function run() external {
        if (config.signerType == DeployConfig.SignerType.ContractWallet) {
            // TODO implement ERC6551 smart wallet interface to enable deployment from PDO TBA
            revert("Contract Wallet Logic not yet implemented");
        } else if (config.signerType == DeployConfig.SignerType.PrivateKey) {
            uint256 deploymentPrivateKey;
            if (block.chainid == 11155111) {
                string memory rawKey = string.concat(
                    "0x",
                    vm.envString("SEPOLIA_PRIVATE_KEY_0")
                );
                deploymentPrivateKey = vm.parseUint(rawKey);
            } else {
                string memory rawKey = string.concat(
                    "0x",
                    vm.envString("ANVIL_PRIVATE_KEY_0")
                );
                deploymentPrivateKey = vm.parseUint(rawKey);
            }
            vm.startBroadcast(deploymentPrivateKey);
        } else {
            // For Ledger/Keystore/Interactive, let forge handle the signing
            vm.startBroadcast();
        }

        if (config.existingRegistryAddress == address(0)) {
            registry = new SyndicateRegistry();
            registryAddress = address(registry);
        } else {
            registryAddress = config.existingRegistryAddress;
            registry = SyndicateRegistry(payable(registryAddress));
        }

        if (config.existingDeployerAddress == address(0)) {
            deployerV1 = new SyndicateDeployerV1(
                registryAddress,
                config.azimuthContract,
                config.deployerFee
            );
            registry.registerDeployer(
                ISyndicateRegistry.SyndicateDeployerData({
                    deployerAddress: address(deployerV1),
                    deployerVersion: 1,
                    isActive: true
                })
            );
        } else {
            deployerV1 = SyndicateDeployerV1(
                payable(config.existingDeployerAddress)
            );
            deployerV1Address = address(deployerV1);

            ISyndicateRegistry.SyndicateDeployerData
                memory deployerData = registry.getDeployerData(
                    deployerV1Address
                );

            if (deployerData.deployerAddress != deployerV1Address) {
                registry.registerDeployer(
                    ISyndicateRegistry.SyndicateDeployerData({
                        deployerAddress: address(deployerV1),
                        deployerVersion: 1,
                        isActive: true
                    })
                );
            }
        }

        syndicateToken = SyndicateTokenV1(
            payable(
                deployerV1.deploySyndicate(
                    config.implementationAddress,
                    config.salt,
                    config.initialSupply,
                    config.maxSupply,
                    config.azimuthPoint,
                    config.tokenName,
                    config.tokenSymbol
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

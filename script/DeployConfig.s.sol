// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO

import {Script} from "@forge-std/Script.sol";
import {console2} from "@forge-std/console2.sol";

contract DeployConfig is Script {
    enum SignerType {
        PrivateKey,
        Ledger,
        Keystore,
        Interactive,
        ContractWallet
    }

    struct NetworkConfig {
        address azimuthContract;
        address existingRegistryAddress;
        address existingDeployerAddress;
        address deploymentAddress;
        address contractWalletAddress;
        address implementationAddress;
        bytes32 salt;
        SignerType signerType;
        uint256 azimuthPoint;
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 maxSupply;
        uint256 deployerFee;
    }

    function getConfig()
        public
        view
        returns (NetworkConfig memory networkConfig)
    {
        SignerType signerType;
        string memory signerTypeStr = vm.envOr(
            "SIGNER_TYPE",
            string("private-key")
        );
        if (keccak256(bytes(signerTypeStr)) == keccak256(bytes("ledger"))) {
            signerType = SignerType.Ledger;
        } else if (
            keccak256(bytes(signerTypeStr)) ==
            keccak256(bytes("contract-wallet"))
        ) {
            signerType = SignerType.ContractWallet;
        } else if (
            keccak256(bytes(signerTypeStr)) == keccak256(bytes("keystore"))
        ) {
            signerType = SignerType.Keystore;
        } else if (
            keccak256(bytes(signerTypeStr)) == keccak256(bytes("interactive"))
        ) {
            signerType = SignerType.Interactive;
        } else {
            signerType = SignerType.PrivateKey;
        }

        address deploymentAddress;
        address contractWalletAddress;
        if (signerType == SignerType.ContractWallet) {
            contractWalletAddress = vm.envAddress("CONTRACT_WALLET_ADDRESS");
            deploymentAddress = contractWalletAddress;
        } else if (signerType == SignerType.PrivateKey) {
            if (block.chainid == 11155111) {
                string memory rawKey = string.concat(
                    "0x",
                    vm.envString("SEPOLIA_PRIVATE_KEY_0")
                );
                deploymentAddress = vm.addr(vm.parseUint(rawKey));
            } else {
                string memory rawKey = string.concat(
                    "0x",
                    vm.envString("ANVIL_PRIVATE_KEY_0")
                );
                deploymentAddress = vm.addr(vm.parseUint(rawKey));
            }
        } else if (signerType == SignerType.Ledger) {
            deploymentAddress = vm.envAddress("LEDGER_ADDRESS");
        } else {
            deploymentAddress = vm.envAddress("DEPLOYMENT_ADDRESS");
        }

        if (block.chainid == 31337) {
            uint256 azimuthPoint = vm.envUint("ANVIL_AZIMUTH_POINT");
            address azimuthContract = vm.envAddress("ANVIL_AZIMUTH_CONTRACT");
            address implementationAddress = vm.envAddress(
                "ANVIL_TBA_IMPLEMENTATION"
            );
            return
                NetworkConfig({ // Local Anvil Devnet
                    azimuthContract: azimuthContract,
                    existingRegistryAddress: address(0),
                    existingDeployerAddress: address(0),
                    deploymentAddress: deploymentAddress,
                    contractWalletAddress: contractWalletAddress,
                    implementationAddress: implementationAddress,
                    salt: bytes32(0),
                    signerType: signerType,
                    azimuthPoint: azimuthPoint,
                    tokenName: "DevNet Syndicate",
                    tokenSymbol: "DEV",
                    initialSupply: 1000000000000000000000000,
                    maxSupply: 21000000000000000000000000,
                    deployerFee: 10000000000000000000
                });
        } else if (block.chainid == 11155111) {
            // Sepolia Testnet
            uint256 azimuthPoint = vm.envUint("SEPOLIA_AZIMUTH_POINT");
            address azimuthContract = vm.envAddress("SEPOLIA_AZIMUTH_CONTRACT");
            address implementationAddress = vm.envAddress(
                "SEPOLIA_TBA_IMPLEMENTATION"
            );
            return
                NetworkConfig({
                    azimuthContract: azimuthContract,
                    existingRegistryAddress: address(0),
                    existingDeployerAddress: address(0),
                    deploymentAddress: deploymentAddress,
                    contractWalletAddress: contractWalletAddress,
                    implementationAddress: implementationAddress,
                    salt: bytes32(0),
                    signerType: signerType,
                    azimuthPoint: azimuthPoint,
                    tokenName: "Sepolia Syndicate",
                    tokenSymbol: "SEP",
                    initialSupply: 1000000000000000000000000,
                    maxSupply: 21000000000000000000000000,
                    deployerFee: 10000000000000000000
                });
        } else if (block.chainid == 1) {
            // Ethereum Mainnet
            uint256 azimuthPoint = vm.envUint("MAINNET_AZIMUTH_POINT");
            address azimuthContract = vm.envAddress("MAINNET_AZIMUTH_CONTRACT");
            address implementationAddress = vm.envAddress(
                "MAINNET_TBA_IMPLEMENTATION"
            );
            return
                NetworkConfig({
                    azimuthContract: azimuthContract,
                    existingRegistryAddress: address(0),
                    existingDeployerAddress: address(0),
                    deploymentAddress: deploymentAddress,
                    contractWalletAddress: contractWalletAddress,
                    implementationAddress: implementationAddress,
                    salt: bytes32(0),
                    signerType: signerType,
                    azimuthPoint: azimuthPoint,
                    tokenName: "Tocwex Syndicate",
                    tokenSymbol: "~TOCWEX",
                    initialSupply: 1000000000000000000000000,
                    maxSupply: 21000000000000000000000000,
                    deployerFee: 10000000000000000000
                });
        }
        revert("Unsupported Network");
    }
}

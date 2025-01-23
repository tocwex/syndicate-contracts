// SPDX-License-Identifier: GPLv3

// TODOs
// properly name all tests
pragma solidity ^0.8.19;

import {Test} from "@forge-std/Test.sol";
import {console2} from "../../lib/forge-std/src/console2.sol";
import {SyndicateTokenV1} from "../../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../../src/SyndicateDeployerV1.sol";
import {ISyndicateDeployerV1} from "../../src/interfaces/ISyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../../src/SyndicateRegistry.sol";
import {ISyndicateRegistry} from "../../src/interfaces/ISyndicateRegistry.sol";
import {ERC721} from "../../lib/openzepplin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "../../lib/openzepplin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC6551Registry} from "../../lib/tokenbound/lib/erc6551/src/ERC6551Registry.sol";
import {IERC6551Registry} from "../../lib/tokenbound/lib/erc6551/src/interfaces/IERC6551Registry.sol";
import {ERC6551Account} from "../../lib/tokenbound/src/abstract/ERC6551Account.sol";

contract SyndicateEcosystemTest is Test {
    ERC6551Registry public tbaRegistry;
    address public tbaRegistryAddress;

    ERC721 public azimuthContract;
    address public azimuthAddress;

    SyndicateRegistry public registry;
    address public registryAddress;

    SyndicateDeployerV1 public deployerV1;
    address public deployerAddress;

    SyndicateTokenV1 public launchedSyndicate;

    address public owner;
    address public alice;
    address public bob;
    address public syndicateOwner;
    uint256 public fee = 100000000000000000;

    address public implementation;
    bytes32 public salt;

    function setUp() public {
        deployerAddress = vm.envAddress("PUBLIC_KEY_0");
        owner = deployerAddress;
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        azimuthContract = new ERC721("Test Azimuth", "AZP");
        azimuthAddress = address(azimuthContract);

        tbaRegistry = new ERC6551Registry();
        tbaRegistryAddress = address(tbaRegistry);

        implementation = makeAddr("implementation");
        salt = bytes32(0);

        vm.startPrank(owner);
        registry = new SyndicateRegistry();
        registryAddress = address(registry);
        deployerV1 = new SyndicateDeployerV1(
            registryAddress,
            azimuthAddress,
            fee
        );
        vm.stopPrank();
    }

    // Helper functions
    //// Registry and Deployer are live
    function _registryAndDeployer() public {
        vm.startPrank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        vm.stopPrank();
    }

    function test_InitialDeployerOwner() public view {
        assertEq(
            owner,
            deployerV1.getOwner(),
            "Owner should be the address that launched the contract"
        );
    }

    function test_ProposeNewOwnerByOwner() public {
        vm.prank(owner);
        registry.proposeNewOwner(bob);
        assertEq(
            bob,
            registry.getPendingOwner(),
            "Pending owner should be proposed owner"
        );
    }

    function test_AcceptOwnershipByPendingOwner() public {
        vm.prank(owner);
        registry.proposeNewOwner(bob);
        assertEq(
            bob,
            registry.getPendingOwner(),
            "Pending owner should be proposed owner"
        );
        vm.prank(bob);
        registry.acceptOwnership();
        assertEq(
            bob,
            registry.getOwner(),
            "Previously pending owner should be owner"
        );
    }

    function _launchSyndicateToken() public {
        syndicateOwner = makeAddr("syndicateOwner");
        vm.prank(syndicateOwner);
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            implementation,
            salt,
            1000000000000000000000000,
            21000000000000000000000000,
            256,
            "Test Token",
            "TES"
        );
        console2.log(
            "Syndicate Contract Launched at: ",
            address(syndicateTokenV1)
        );
        launchedSyndicate = SyndicateTokenV1(payable(syndicateTokenV1));
        console2.log("syndicateOwner: ", launchedSyndicate.getOwner());
        console2.log("initialSupply: ", launchedSyndicate.totalSupply());
        console2.log("maxSupply: ", launchedSyndicate.getMaxSupply());
        console2.log("azimiuthPoint: ", launchedSyndicate.getAzimuthPoint());
        console2.log("name: ", launchedSyndicate.name());
        console2.log("symbol: ", launchedSyndicate.symbol());
    }

    // Admin checks
    function testContractSizes() public {
        uint256 registrySize;
        uint256 deployerSize;
        uint256 tokenSize;

        _registryAndDeployer();
        _launchSyndicateToken();

        address registryAddr = address(registry);
        address deployerAddr = address(deployerV1);
        address tokenAddr = address(launchedSyndicate);

        assembly {
            registrySize := extcodesize(registryAddr)
            deployerSize := extcodesize(deployerAddr)
            tokenSize := extcodesize(tokenAddr)
        }

        console2.log("Registry contract size:", registrySize);
        console2.log("Deployer contract size:", deployerSize);
        console2.log("Token contract size:", tokenSize);
    }

    // Ownership Transfer Tests

    function test_InitialRegistryOwner() public view {
        assertEq(
            owner,
            registry.getOwner(),
            "Registry owner should be the address that launched the contract"
        );
    }

    function test_ProposeNewOwner() public {
        vm.prank(deployerAddress);
        registry.proposeNewOwner(bob);
        // TODO add expectEmit
        assertEq(
            bob,
            registry.getPendingOwner(),
            "Pending Owner should be _pendingOwner"
        );
    }

    function test_AcceptOwnership() public {
        vm.prank(deployerAddress);
        registry.proposeNewOwner(bob);
        vm.prank(bob);
        registry.acceptOwnership();
        // TODO add expectEmit
        assertEq(
            bob,
            registry.getOwner(),
            "Owner should be pending owner that called the acceptOwner function"
        );
    }

    //// TODO add reject ownership proposal test
    //// TODO add nullify ownership proposal test
    //// TODO add renounce ownership test

    // Getter function tests
    //// TODO add test for getter functions if necessary

    // Deployer Registration Tests
    function test_RegisterNewDeployerByOwner() public {
        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerRegistered(
            address(deployerV1),
            1,
            true
        );

        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        // TODO add more complex version numbering or logic checks?
        assertEq(
            true,
            registry.isRegisteredDeployer(address(deployerV1)),
            "Is not registered deployment"
        );
        // TODO add expect Emit
    }

    // TODO add test of adding a second deployer

    function testFail_RegisterNewDeployerByNotOwner() public {
        vm.prank(bob);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    function testFuzz_RegisterNewDeployerByNotOwner(
        address[] calldata randomCallers
    ) public {
        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert();
            registry.registerDeployer(
                ISyndicateRegistry.SyndicateDeployerData({
                    deployerAddress: address(deployerV1),
                    deployerVersion: 1,
                    isActive: true
                })
            );
        }
    }

    //// Deactivation Tests
    function test_DeactivateRegisteredDeployerByOwner() public {
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerDeactivated(address(deployerV1), false);

        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        ISyndicateRegistry.SyndicateDeployerData memory currentData = registry
            .getDeployerData(address(deployerV1));

        assertEq(currentData.isActive, false, "Deployer should be deactivated");
    }

    function testFail_DeactivateRegisteredDeployerByNotOwner() public {
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.prank(bob);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    //// Reactivation Tests

    function test_ReactivateRegisteredDeployerByOwner() public {
        // Register the deployer
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerDeactivated(address(deployerV1), false);

        // Deactivate the deployer
        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        ISyndicateRegistry.SyndicateDeployerData memory currentData = registry
            .getDeployerData(address(deployerV1));

        assertEq(
            currentData.isActive,
            false,
            "Deployer should be deactivated at this stage"
        );

        // Reactivate the Deployer
        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerReactivated(address(deployerV1), true);

        vm.prank(owner);
        registry.reactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData memory newData = registry
            .getDeployerData(address(deployerV1));

        assertEq(
            newData.isActive,
            true,
            "Deployer should be reactivated at this stage"
        );
    }

    function testFail_ReactivateRegisteredDeployerByNotOwner() public {
        // Register the deployer
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerDeactivated(address(deployerV1), false);

        // Deactivate the deployer
        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        ISyndicateRegistry.SyndicateDeployerData memory currentData = registry
            .getDeployerData(address(deployerV1));

        assertEq(
            currentData.isActive,
            false,
            "Deployer should be deactivated at this stage"
        );

        // Attempt to reactivate the Deployer as non-owner
        vm.prank(bob);
        registry.reactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    // TODO add test for failing to register a deployer with a version number matching that of an already existant deployer
    // TODO add test_ChangeSyndicateDeployerFeeRecipient

    // Syndicate Launching Tests
    function test_LaunchAndRegisterNewSyndicate() public {
        _registryAndDeployer();
        _launchSyndicateToken();
        assertEq(
            launchedSyndicate.getOwner(),
            syndicateOwner,
            "Syndicate owner mismatch"
        );
    }

    function test_UpdateSyndicateOwnershipAddress() public {
        _registryAndDeployer();
        _launchSyndicateToken();
        vm.prank(address(syndicateOwner));
        address newOwnershipTba = makeAddr("newTBA");
        launchedSyndicate.updateOwnershipTba(
            newOwnershipTba,
            implementation,
            salt
        );
        console2.log(
            "New Owner of ",
            address(launchedSyndicate),
            "is: ",
            launchedSyndicate.getOwner()
        );
        assertEq(
            newOwnershipTba,
            launchedSyndicate.getOwner(),
            "Syndicate Token Owner failed to update properly"
        );
    }

    // TODO testFail_UpdateSyndicateOwnershipAddressAsNotOwner

    // Syndicate Management
}

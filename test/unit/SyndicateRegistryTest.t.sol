// SPDX-License-Identifier: GPLv3

// TODOs
//
pragma solidity ^0.8.19;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";
import {SyndicateTokenV1} from "../../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../../src/SyndicateDeployerV1.sol";
import {ISyndicateDeployerV1} from "../../src/interfaces/ISyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../../src/SyndicateRegistry.sol";
import {ISyndicateRegistry} from "../../src/interfaces/ISyndicateRegistry.sol";

contract SyndicateRegistryTest is Test {
    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    address public owner;
    address public alice;
    address public bob;
    address public deployerAddress;

    function setUp() public {
        deployerAddress = vm.envAddress("PUBLIC_KEY_0");
        owner = deployerAddress;
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        registry = new SyndicateRegistry();
        deployerV1 = new SyndicateDeployerV1();
        vm.stopPrank();
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

    // Registration Tests
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
}

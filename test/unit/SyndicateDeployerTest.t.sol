// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
//
import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";
import {SyndicateTokenV1} from "../../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../../src/SyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../../src/SyndicateRegistry.sol";

contract SyndicateDeployerTest is Test {
    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    address public owner;
    address public alice;
    address public bob;
    uint256 public fee = 100000000000000000;
    address public registryAddress;

    function setUp() public {
        owner = vm.envAddress("PUBLIC_KEY_0");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        registry = new SyndicateRegistry();
        registryAddress = address(registry);
        vm.prank(owner);
        deployerV1 = new SyndicateDeployerV1(registryAddress, fee);
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
        deployerV1.proposeNewOwner(bob);
        assertEq(
            bob,
            deployerV1.getPendingOwner(),
            "Pending owner should be proposed owner"
        );
    }

    function test_AcceptOwnershipByPendingOwner() public {
        vm.prank(owner);
        deployerV1.proposeNewOwner(bob);
        assertEq(
            bob,
            deployerV1.getPendingOwner(),
            "Pending owner should be proposed owner"
        );
        vm.prank(bob);
        deployerV1.acceptOwnership();
        assertEq(
            bob,
            deployerV1.getOwner(),
            "Previously pending owner should be owner"
        );
    }

    // TODO add test for rejectOwnership()
    // TODO add test for nullifyProposal()
    // TODO add test for checkElligibility()
}

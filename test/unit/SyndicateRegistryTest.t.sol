// SPDX-License-Identifier: GPLv3

// TODOs
//
pragma solidity ^0.8.19;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";
import {SyndicateTokenV1} from "../../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../../src/SyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../../src/SyndicateRegistry.sol";

contract SyndicateRegistryTest is Test {
    SyndicateRegistry public registry;
    address public owner;
    address public alice;
    address public bob;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        registry = new SyndicateRegistry();
    }

    function test_InitialOwner() public view {
        assertEq(
            owner,
            address(this),
            "Owner should be the address that launched the contract"
        );
    }
}

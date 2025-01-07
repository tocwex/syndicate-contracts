// SPDX-License-Identifier: GPLv3

// TODOs
//
pragma solidity ^0.8.19;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";
import {SyndicateTokenV1} from "../../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../../src/SyndicateDeployerV1.sol";

contract SyndicateTokenTest is Test {
    SyndicateTokenV1 public syndicateTokenV1;
    SyndicateDeployerV1 public syndicateDeployerV1;

    // Environment Variables
    address owner = makeAddr("bob");
    uint256 initialSupply = 100 * 10 ** 18;
    uint256 maxSupply = 1000 * 10 ** 18;
    string name = "Syndicate Token";
    string symbol = "SYN";

    address recipient = makeAddr("alice");

    function setUp() public {
        syndicateDeployerV1 = new SyndicateDeployerV1();
        console.log("Deployer launched at: ", address(syndicateDeployerV1));
        vm.startPrank(address(syndicateDeployerV1));
        syndicateTokenV1 = SyndicateTokenV1(
            syndicateDeployerV1.DeployToken(
                owner,
                initialSupply,
                maxSupply,
                name,
                symbol
            )
        );
        console.log("Contract deployed at: ", address(syndicateTokenV1));
        vm.stopPrank();
    }

    function testContractAddress() public view returns (SyndicateTokenV1) {
        return syndicateTokenV1;
    }

    function testTokenCreation() public view {
        assertEq(syndicateTokenV1.totalSupply(), initialSupply);
    }

    function testCheckMaxSupply() public view {
        console.log("The initial supply is: ", initialSupply);
        console.log("The max supply is: ", maxSupply);
        assertEq(maxSupply, syndicateTokenV1.maxSupply());
    }
    //
    // function testTransfer() public {}
    //
    // function testCheckBalance() public {}
}

// SPDX-License-Identifier: GPLv3

// TODOs
//
pragma solidity ^0.8.19;

import {Test} from "@forge-std/Test.sol";
import {console} from "@forge-std/console.sol";
import {SyndicateToken} from "../../src/SyndicateToken.sol";
import {SyndicateDeployer} from "../../src/SyndicateDeployer.sol";

contract SyndicateTokenTest is Test {
    SyndicateToken public syndicateToken;
    SyndicateDeployer public syndicateDeployer;

    // Environment Variables
    address owner = makeAddr("bob");
    uint256 initialSupply = 100 * 10 ** 18;
    uint256 maxSupply = 1000 * 10 ** 18;
    string name = "Syndicate Token";
    string symbol = "SYN";

    address recipient = makeAddr("alice");

    function setUp() public {
        syndicateDeployer = new SyndicateDeployer();
        console.log("Deployer launched at: ", address(syndicateDeployer));
        vm.startPrank(address(syndicateDeployer));
        syndicateToken = SyndicateToken(
            syndicateDeployer.DeployToken(
                owner,
                initialSupply,
                maxSupply,
                name,
                symbol
            )
        );
        console.log("Contract deployed at: ", address(syndicateToken));
        vm.stopPrank();
    }

    function testContractAddress() public view returns (SyndicateToken) {
        return syndicateToken;
    }

    function testTokenCreation() public view {
        assertEq(syndicateToken.totalSupply(), initialSupply);
    }

    function testCheckMaxSupply() public view {
        console.log("The initial supply is: ", initialSupply);
        console.log("The max supply is: ", maxSupply);
        assertEq(maxSupply, syndicateToken.maxSupply());
    }
    //
    // function testTransfer() public {}
    //
    // function testCheckBalance() public {}
}

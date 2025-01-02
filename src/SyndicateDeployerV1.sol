// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment factory contract to:
// keep a list of @p to token address + token version number
//// each @p gets only one token (can they overwrite? maybe they can chose on launch?)
// contract proxy address
// constructor values for: fee percentage, fee recipient (~tocwex TBA)
// access control list by TBA address (How do I do TBA lookup onchain?)
// upgradable contract proxy
// ownable deployment factory, but no control over the ledger

import {ISyndicateRegistry} from "./SyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";

interface ISyndicateDeployerV1 {
    // Events
    event TokenDeployed();

    // Errors
    error Unauthorized();
}

contract SyndicateDeployerV1 is ISyndicateDeployerV1 {
    // deploy function should call to the registry contract to:
    // check that the deployer is active
    // add the syndicate token to the registery
    // Structs

    // Variables
    ISyndicateRegistry public immutable registry; // = "0x123..."; TODO hardcode the registry contract

    // Mappings

    // Modifiers

    // Constructor
    constructor() {
        revert("Not yet implemented");
    }

    // Functions
    function DeploySyndicate(
        address owner,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory name,
        string memory symbol
    ) public returns (address) {
        // token logic
        // require(
        //     owner == msg.sender,
        //     "Only the TBA of an L1 identity can launch a token"
        // );
        SyndicateTokenV1 syndicateTokenV1 = new SyndicateTokenV1(
            owner,
            initialSupply,
            maxSupply,
            name,
            symbol
        );
        emit TokenDeployed(address(syndicateTokenV1), owner);
        return address(syndicateTokenV1);
    }
}

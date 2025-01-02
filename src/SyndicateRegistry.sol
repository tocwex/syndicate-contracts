// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

import {Ownable} from "@openzepplin/access/Ownable.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "./SyndicateDeployerV1.sol";

interface ISyndicateRegistry {
    // Events
    // TODO emit events from functions
    //// Deployer Events
    event DeployerRegistered(
        address indexed syndicateDeployer,
        string deployerVersion
    );
    event DeployerRemoved(address indexed syndicateDeployer);

    //// Ownership Events
    event OwnerUpdated(address previousOwner, address newOwner);
    event OwnershipRejected(address pendingOwner, address previousOwner); // not sure about the parameters here

    //// Syndicate Events
    event SyndicateLaunched(
        address indexed syndicateToken,
        address indexed owner,
        string name,
        string symbol
    );

    // Errors
    error Unauthorized();
}

contract SyndicateRegistry is ISyndicateRegistry {
    // Structs and types
    struct SyndicateDeployerData {
        address deployerOwner;
        address deployerAddress;
        string version;
        bool isActive;
    }

    struct Syndicate {
        address syndicateOwner;
        address syndicateContract;
        SyndicateDeployerData syndicateDeploymentData;
        uint256 syndicateLaunchTime; // block height
    }
    // TODOS for Structs
    // Add Syndicate types by galaxy/star/galaxyplanet?
    // If I add these now, future deployers could check against the registry and
    // allow or disallow the deployer from adding a syndicate to the SyndicateRegistry

    // State Variables
    address public owner;
    address public pendingOwner;
    Syndicate public syndicate;

    // Mappings
    mapping(address => SyndicateDeployerData) public deployerData; // Deployer address => deployer data
    mapping(address => Syndicate) public syndicateData; // owner address => contract address

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, Unauthorized());
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, Unauthorized());
        _;
    }

    // Constructor

    constructor() {
        // constructor sets initial owner
        owner = msg.sender;
    }

    // Functions
    function addDeployer(
        address deployer,
        string calldata version
    ) public onlyOwner {
        revert("Not implemented");
        // Do we want to limit to one deployer per version? I suspect 'yes'
    }

    function removeDeployer() public onlyOwner {
        revert("Not implemented");
        // what should removing a deployer do? probably make it no longer callable
        // this would mean the deployers should include a registry check modifier.
    }

    function addSyndicate() public {
        revert("Not implemented");
        // this should only be callable by active deployers
        // where does the check happen to ensure there is a 1:1 mapping of @p to token?
    }

    function updateOwner() public onlyOwner {
        revert("Not implemented");
        // do we want this to be a 2-step ownership transfer? Probably, since it is such a vital ecosystem element
    }

    function acceptOwnership() public onlyPendingOwner {
        revert("Not implemented");
        // logic for pending owner to accept or reject ownership
    }
}

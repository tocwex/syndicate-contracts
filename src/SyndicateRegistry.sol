// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;
// TODO: where does the fee recipient address actually belong? presumably it should be set
// at a single level and then referenced by the respective ERC20 contracts. Alternatively we could
// make it immutable as the TBA of ~tocwex? It is currently set in the Deployer contracts, but should
// probably be moved here to the registry contract.
// TODO implement receive and fallback Functions

// import {Ownable} from "@openzepplin/access/Ownable.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "./SyndicateDeployerV1.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";

contract SyndicateRegistry is ISyndicateRegistry {
    // State Variables
    address public owner;
    address public pendingOwner;
    Syndicate public syndicate;
    SyndicateDeployerData public syndicateDeployer;

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

    modifier onlyValidDeployer() {
        // TODO check this logic; synidcateDeployer might need to be an array or have a better mapping?
        require(
            msg.sender == syndicateDeployer.deployerAddress,
            Unauthorized()
        );
        _;
    }

    // Constructor

    constructor() {
        // constructor sets initial owner
        owner = msg.sender;
    }

    // Functions
    //// External Functions
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

    function registerSyndicate(Syndicate syndicate) public onlyValidDeployer {
        revert("Not implemented");
        // this should only be callable by active deployers
        // where does the check happen to ensure there is a 1:1 mapping of @p to token?
    }

    function updateOwner(
        address pendingOwner
    ) public onlyOwner returns (bool success) {
        revert("Not implemented");
        // do we want this to be a 2-step ownership transfer? Probably, since it is such a vital ecosystem element
    }

    function acceptOwnership() public onlyPendingOwner returns (bool success) {
        revert("Not implemented");
        // logic for pending owner to accept or reject ownership
    }
}

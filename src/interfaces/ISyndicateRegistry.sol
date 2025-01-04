// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

interface ISyndicateRegistry {
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

    // Events
    //// Deployer Events
    /// @notice emitted when a deployer is added to the registry
    /// @dev
    /// @param syndicateDeployer The address of the newly registered Deployer
    /// @param deployerVersion The version number of the deployer
    /// @param isActive The registration eligibility of the deployer, should be true on initial registration
    event DeployerRegistered(
        address indexed syndicateDeployer,
        string deployerVersion,
        bool isActive
    );

    /// @notice emitted when a deployer is deactivated on the registry
    /// @dev Removal of a deployer sets isActive to false, but retains data in contract storage for reference purposes
    /// @param syndicateDeployer The deployer contract address
    /// @param isActive The registration eligibility of the deployer, should be false on removal
    event DeployerRemoved(address indexed syndicateDeployer, bool isActive);

    //// Ownership Events
    /// @notice emitted when an ownership transfer is proposed
    /// @dev
    /// @param pendingOwner The proposed new owner for the registry contract
    /// @param registryOwner The current owner of the registry contract
    event OwnerProposed(address pendingOwner, address registryOwner);

    /// @notice emitted when ownership transfer is accepted
    /// @dev
    /// @param previousOwner The old owner of the registry contract
    /// @param newOwner The new owner of the registry contract
    event OwnerUpdated(address previousOwner, address newOwner);

    /// @notice emitted when the ownership transfer is rejected by pendingOwner
    /// @dev
    /// @param pendingOwner The address that rejected ownership control of the registry
    /// @param previousOwner The address that retains ownership control of the registry
    event OwnershipRejected(address pendingOwner, address previousOwner); // not sure about the parameters here

    /// @notice emitted when the owner permanently renounced ownership to the null address
    /// @dev
    /// @param previousOwner The address that ultimately renounced ownership of the registry
    event OwnershipRenounced(address previousOwner);

    //// Syndicate Events
    /// @notice emitted when a new syndicate token is properly registered
    /// @dev this is a relatively expensive event to call and should be used sparingly
    /// @param deployerAddress The contract address of the SyndicateDeployer used
    /// @param syndicateToken The contract address of the newly registered token
    /// @param owner the ownership address of the newly registered token
    event SyndicateRegistered(
        address indexed deployerAddress,
        address indexed syndicateToken,
        address indexed owner
    );

    // Errors
    error Unauthorized();

    // Functions
    /// @notice Called to add a new deployer to the Syndicate Registry
    /// @dev should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been added to the registry
    function addDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external returns (bool success);

    /// @notice Called to deactivate deployer in the Syndicate Registry
    /// @dev Function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been deactivated in the registry
    function removeDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external returns (bool success);

    /// @notice Called by an active Syndicate Deployer to launch a Syndicate Token
    /// @dev should only be callable by an active Syndicate Deployer
    /// @param syndicate See {Syndicate} for struct documentation
    // TODO what parameters are to be provided by the deployer contract? what should be returned
    // from this function? is it really just a (bool success) or perhaps nothing?
    function registerSyndicate(
        Syndicate calldata syndicate
    ) external returns (bool success);

    /// @notice called calldata by Syndicate Registry owner to propose new ownership keys
    /// @dev should only be callable by current contract owner
    /// @param pendingOwner The address of the proposed new owner
    function updateOwner(address pendingOwner) external returns (bool success);

    /// @notice Called by pendingOwner to accept ownership of Syndicate Registry contract
    /// @dev should only be callable by pendingOwner
    function acceptOwnership() external returns (bool success);

    /// @notice Called by pendingOwner to reject ownership of Syndicate Registry contract
    /// @dev should only be callable by pendingOwner
    function rejectOwnership() external returns (bool success);

    /// @notice Called by Syndicate Registry owner to nullify the new owner proposal
    /// @dev should only be callable by registry contract owner
    function nullifyProposal() external returns (bool success);
}

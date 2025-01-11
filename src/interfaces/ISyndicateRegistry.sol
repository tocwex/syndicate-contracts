// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

interface ISyndicateRegistry {
    // Structs and types
    struct SyndicateDeployerData {
        address deployerAddress; // 20 bytes
        uint64 deployerVersion; // 8 bytes
        bool isActive; // 1 byte
    }

    struct Syndicate {
        address syndicateOwner;
        address syndicateContract;
        SyndicateDeployerData syndicateDeploymentData;
        uint256 syndicateLaunchTime; // block height
        uint256 azimuthPoint; // token ID of Azimuth NFT
        // NOTE: Azimuth point's are included and explicitly not filtered by
        // location in the hierarchy in the Registry contract. Filtering or
        // additional permissions are to be implemented either on frontend
        // interfaces, or in the deployer logic
    }

    // Events
    //// Deployer Events
    /// @notice emitted when a deployer is added to the registry
    /// @dev
    /// @param syndicateDeployer The address of the newly registered Deployer
    /// @param deployerVersion The version number of the deployer
    /// @param isActive The registration eligibility of the deployer, should be true on initial registration
    event DeployerRegistered(
        address indexed syndicateDeployer,
        uint64 deployerVersion,
        bool isActive
    );

    /// @notice emitted when a deployer is deactivated on the registry
    /// @dev Deativation of a deployer sets isActive to false, but retains data in contract storage for reference purposes
    /// @param syndicateDeployer The deployer contract address
    /// @param isActive The registration eligibility of the deployer, should be false on deactivation
    event DeployerDeactivated(address indexed syndicateDeployer, bool isActive);

    /// @notice emitted when a deployer is activated on the registry
    /// @dev Activation of a deployer sets isActive to true
    /// @param syndicateDeployer The deployer contract address
    /// @param isActive The registration eligibility of the deployer, should be true on activation
    event DeployerReactivated(address indexed syndicateDeployer, bool isActive);

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

    /// @notice emitted when the owner nullifies the proposed ownership transfer
    /// @dev
    /// @param registryOwner The address which owns the registry contract
    event ProposalNullified(address registryOwner);

    /// @notice emitted when the owner permanently renounced ownership to the null address
    /// @dev
    /// @param previousOwner The address that ultimately renounced ownership of the registry
    event OwnershipRenounced(address previousOwner);

    // Errors
    error Unauthorized();

    // Functions
    //// Deployer management functions

    /// @notice Called to add a new deployer to the Syndicate Registry
    /// @dev should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been added to the registry
    function registerDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external returns (bool success);

    /// @notice Called to deactivate deployer in the Syndicate Registry
    /// @dev Function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been deactivated in the registry
    function deactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external returns (bool success);

    /// @notice Called to reactivate deployer in the Syndicate Registry
    /// @dev Function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been reactivated in the registry
    function reactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external returns (bool success);

    //// Syndicate registry functions

    /// @notice Called by an active Syndicate Deployer to launch a Syndicate Token
    /// @dev should only be callable by an active Syndicate Deployer
    /// @param syndicate See {Syndicate} for struct documentation
    // TODO what parameters are to be provided by the deployer contract? what should be returned
    // from this function? is it really just a (bool success) or perhaps nothing?
    function registerSyndicate(
        Syndicate calldata syndicate
    ) external returns (bool success);

    //// Ownership transfer functions

    /// @notice called calldata by Syndicate Registry owner to propose new ownership keys
    /// @dev should only be callable by current contract owner
    /// @param pendingOwner The address of the proposed new owner
    function proposeNewOwner(
        address proposedOwner
    ) external returns (address pendingOwner, address owner);

    /// @notice Called by pendingOwner to accept ownership of Syndicate Registry contract
    /// @dev should only be callable by pendingOwner
    /// @return success Confirmation the ownership has been accepted by the pendingOwner
    function acceptOwnership() external returns (bool success);

    /// @notice Called by pendingOwner to reject ownership of Syndicate Registry contract
    /// @dev should only be callable by pendingOwner
    /// @return success Confirmation of onchain rejection of ownership rights by pendingOwner
    function rejectOwnership() external returns (bool success);

    /// @notice Called by Syndicate Registry owner to nullify the new owner proposal
    /// @dev should only be callable by registry contract owner and should prevent transfer to the null address
    /// @return success Confirmation of revocation of ownership transfer proposal
    function nullifyProposal() external returns (bool success);

    /// @notice Called by Syndicate Registry owner to renounce ownership to the null address
    /// @dev should only be callable by the registry contract owner
    /// @return success Confirmation of renouncing ownership to the null address
    function renounceOwnership() external returns (bool success);
}

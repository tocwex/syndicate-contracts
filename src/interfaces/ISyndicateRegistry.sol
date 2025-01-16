// SPDX-License-Identifier: GPLv3

// TODO Finish Natspec
pragma solidity ^0.8.19;

interface ISyndicateRegistry {
    // Structs
    // TODO add natspec
    struct SyndicateDeployerData {
        address deployerAddress; // 20 bytes
        uint64 deployerVersion; // 8 bytes
        bool isActive; // 1 byte
    }

    // TODO add natspec
    struct Syndicate {
        address syndicateOwner; // 20 bytes
        address syndicateContract; // 20 bytes
        SyndicateDeployerData syndicateDeploymentData; // 32 bytes / 1 slot
        uint256 syndicateLaunchTime; // 32 bytes / blockheight
        uint256 azimuthPoint; // 32 bytes / token ID of Azimuth NFT
        // NOTE: Azimuth point's are included and explicitly not filtered by
        // location in the hierarchy in the Registry contract. Filtering or
        // additional permissions are to be implemented either on frontend
        // interfaces, or in the deployer logic
        // Note that this could be a uint16 but will take a full slot anyways
        // so leaving as uint256 for future optionality (Groundwire Comet
        // Tokens, anyone?)
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

    // TODO add natspec
    event SyndicateOwnerUpdated(
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
    /// @param proposedOwner The address that rejected ownership control of the registry
    /// @param retainedOwner The address that retains ownership control of the registry
    event OwnershipRejected(address proposedOwner, address retainedOwner);

    /// @notice emitted when the owner nullifies the proposed ownership transfer
    /// @dev
    /// @param registryOwner The address which owns the registry contract
    /// @param proposedOwner The address removed from proposed owner role
    event ProposalNullified(address registryOwner, address proposedOwner);

    /// @notice emitted when the owner permanently renounced ownership to the null address
    /// @dev
    /// @param previousOwner The address that ultimately renounced ownership of the registry
    event OwnershipRenounced(address previousOwner);

    // Errors
    // error Unauthorized();

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

    /// @notice Called by an active syndicate deployer to update the owner of a Syndicate token contract
    /// @dev should only be callable by an active Syndicate Deployer
    /// @param syndicateToken The address of the syndicate token contract
    /// @param newOwner The address of the proposed new owner of the syndicateToken contact
    /// @return success Boolean for transaction completion
    function updateSyndicateOwnerRegistration(
        address syndicateToken,
        address newOwner
    ) external returns (bool success);

    //// Ownership transfer functions

    /// @notice called calldata by Syndicate Registry owner to propose new ownership keys
    /// @dev should only be callable by current contract owner
    /// @param proposedOwner The address of the proposed new owner
    function proposeNewOwner(
        address proposedOwner
    ) external returns (bool success);

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

    /// @notice Getter fuction for _owner private state variable
    /// @return owner Ownership address of Registry contract which has the rights to add new deployers to the registry
    function getOwner() external view returns (address owner);

    /// @notice Getter fuciton for _pending owner private state variable
    /// @return pendingOwner Address for pending owner of the registry contract which can accept or reject the ownership proposal
    function getPendingOwner() external view returns (address pendingOwner);

    /// @notice Getter function to check if an address is a registered deployer
    /// @dev Existence of deployer does not guarantee that the deployer is active; call getDeployerData for that state.
    /// @return isRegistered Boolean indicating that the address is including in the registry as a deployer
    function isRegisteredDeployer(
        address checkAddress
    ) external view returns (bool isRegistered);

    /// @notice Getter function to retrieve an array of addresses for all registered deployers
    /// @return syndicateDeployers Array of addresses which are valid Deployer contracts, which may or may not be active.
    function getDeployers()
        external
        view
        returns (address[] memory syndicateDeployers);

    /// @notice Getter function to retrieve the contents of a SyndicateDeployerData struct for the given address
    /// @param deployerAddress The address of a deployer contract in the syndicateDeployers array
    /// @return syndicateDeployerData A struct containing {SyndicateDeployerData} data
    function getDeployerData(
        address deployerAddress
    )
        external
        view
        returns (SyndicateDeployerData memory syndicateDeployerData);
}

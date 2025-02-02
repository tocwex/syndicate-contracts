// SPDX-License-Identifier: GPLv3

// TODO Finish Natspec
pragma solidity ^0.8.19;

interface ISyndicateRegistry {
    // Structs
    /// @title Syndicate Deployer Data Structure
    /// @notice Struct for data about Syndicate Deployer contract to be stored in an array in the Registry contract
    /// @dev
    struct SyndicateDeployerData {
        /// @notice The address of a deployer contract
        /// @dev Deliberately takes any address to leave optionality for implementation details and interface updates of future SyndicateDeployer contracts
        address deployerAddress; // 20 bytes
        /// @notice The version of a given deployer contract
        /// @dev Only one deplover of any given version should be deployed and recorded.
        uint64 deployerVersion; // 8 bytes
        /// @notice The state of a given deployer contract
        /// @dev Inactive deployers should not be able to launch additional Syndicate Token Contracts, but should be able to change the ownership address of a given token.
        bool isActive; // 1 byte
    }

    /// @title Syndicate Data Structure
    /// @notice Struct for data about Syndicate token contracts to be stored in a mapping in the Syndicate Registry contract
    /// @dev Designed as a relatively open ended datastructure for referencing deployed contracts to enable flexible future Syndicate Deployer implementations with additional featurs
    struct Syndicate {
        /// @notice Address of the token contract owner, which MUST be a valid IERC6551Account associated with the azimuthPoint of the controlling Urbit ID
        address syndicateOwner;
        /// @notice Address of the token contract, which must be a valid IERC20 contract
        address syndicateContract;
        /// @notice Address of the deployer contract which the syndicate was launched from
        address syndicateDeployer;
        /// @notice Blockheight at which the Syndicate Token contract is launched
        uint256 syndicateLaunchTime;
        /// @notice Azimuth Point / `@ud`~sampel of the associated Urbit ID for this Syndicate Token
        /// @dev Azimuth point's are included and explicitly not filtered by location in the hierarchy in the Registry contract. Filtering or additional permissions are to be implemented either on frontend interfaces, or in the deployer logic. Note that this could be a uint16 but will take a full slot anyways so leaving as uint256 for future optionality (Groundwire Comet Tokens, anyone?)
        uint256 azimuthPoint;
    }

    // Events
    //// Deployer Contract Events
    /// @notice emitted when a deployer is added to the registry
    /// @dev
    /// @param syndicateDeployer The address of the newly registered Deployer
    /// @param deployerVersion The version number of the deployer
    /// @param isActive The registration eligibility of the deployer, should be true on initial registration
    event DeployerRegistered(address indexed syndicateDeployer, uint64 deployerVersion, bool isActive);

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

    //// Syndicate Contract Events
    /// @notice emitted when a new syndicate token is properly registered
    /// @dev this is a relatively expensive event to call and should be used sparingly
    /// @param deployerAddress The contract address of the SyndicateDeployer used
    /// @param syndicateToken The contract address of the newly registered token
    /// @param owner the ownership address of the newly registered token
    event SyndicateRegistered(
        address indexed deployerAddress, address indexed syndicateToken, address indexed owner, uint256 azimuthPoint
    );

    // TODO add Natspec
    event SyndicateDissolved(
        address indexed deployerAddress, address indexed syndicateToken, address indexed owner, uint256 azimuthPoint
    );

    /// @notice emitted when a syndicate token owner is successfully updated
    /// @dev The owner address emitted here MUST be confirmed to be a valid TBA for the syndicate token's azimuth point
    /// @param deployerAddress The address of the deployer associated with the updated syndicate token
    /// @param syndicateToken The token contract address which just had it's owner updated
    /// @param owner The address of the new owner of the token contract
    event SyndicateOwnerUpdated(address indexed deployerAddress, address indexed syndicateToken, address indexed owner);

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
    function registerDeployer(SyndicateDeployerData calldata syndicateDeployerData) external returns (bool success);

    /// @notice Called to deactivate deployer in the Syndicate Registry
    /// @dev Function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been deactivated in the registry
    function deactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData) external returns (bool success);

    /// @notice Called to reactivate deployer in the Syndicate Registry
    /// @dev Function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been reactivated in the registry
    function reactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData) external returns (bool success);

    //// Syndicate registry functions

    /// @notice Called by an active Syndicate Deployer to launch a Syndicate Token
    /// @dev should only be callable by an active Syndicate Deployer, and the syndicate deployer MUST implement the check to ensure only a valid TBA may register a syndicate and create a mapping(uint256 => Syndicate) in the process.
    /// @param syndicate See {Syndicate} for struct documentation
    function registerSyndicate(Syndicate calldata syndicate) external returns (bool success);

    // TODO add natspec
    function dissolveSyndicate(Syndicate calldata syndicate) external returns (bool success);

    /// @notice Called by an active syndicate deployer to update the owner of a Syndicate token contract
    /// @dev should only be callable by an active Syndicate Deployer, and the syndicate deployer MUST implement the check to ensure only a valid TBA may be made the owner of a given syndicate, updating the mapping(uint256 => Syndicate) in the process.
    /// @param syndicateToken The address of the syndicate token contract
    /// @param newOwner The address of the proposed new owner of the syndicateToken contact
    /// @return success Boolean for transaction completion
    function updateSyndicateOwnerRegistration(address syndicateToken, address newOwner)
        external
        returns (bool success);

    //// Ownership transfer functions

    /// @notice called calldata by Syndicate Registry owner to propose new ownership keys
    /// @dev should only be callable by current contract owner
    /// @param proposedOwner The address of the proposed new owner
    function proposeNewOwner(address proposedOwner) external returns (bool success);

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
    function isRegisteredDeployer(address checkAddress) external view returns (bool isRegistered);

    /// @notice Getter function to check if deployer is currently active
    /// @dev Deployer must be active in order to allow launching of new syndicate tokens
    /// @param checkAddress The address of the deployer for which you want to check active state
    /// @return isActive The state of the deployer
    function isActiveDeployer(address checkAddress) external view returns (bool isActive);

    /// @notice Getter function to retrieve an array of addresses for all registered deployers
    /// @return syndicateDeployers Array of addresses which are valid Deployer contracts, which may or may not be active.
    function getDeployers() external view returns (address[] memory syndicateDeployers);

    /// @notice Getter function to retrieve the contents of a SyndicateDeployerData struct for the given address
    /// @param deployerAddress The address of a deployer contract in the syndicateDeployers array
    /// @return syndicateDeployerData A struct containing {SyndicateDeployerData} data
    function getDeployerData(address deployerAddress)
        external
        view
        returns (SyndicateDeployerData memory syndicateDeployerData);

    function getSyndicateTokenExistsUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (bool syndicateExists);

    function getSyndicateTokenAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateAddress);

    function getSyndicateTokenOwnerAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateOwner);

    function getSyndicateTokenDeployerAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateDeployerAddress);

    function getSyndicateTokenDeployerVersionUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (uint64 syndicateDeployerVersion);

    function getSyndicateTokenDeployerIsActiveUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (bool syndicateDeployerIsActive);

    function getSyndicateTokenLaunchTimeUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (uint256 syndicateLaunchTime);

    function getSyndicateTokenExistsUsingAddress(address checkAddress) external view returns (bool syndicateExists);

    function getSyndicateAzimuthPointUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateAddress);

    function getSyndicateTokenOwnerAddressUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateOwner);

    function getSyndicateTokenDeployerAddressUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateDeployerAddress);

    function getSyndicateTokenDeployerVersionUsingAddress(address checkAddress)
        external
        view
        returns (uint64 syndicateDeployerVersion);

    function getSyndicateTokenDeployerIsActiveUsingAddress(address checkAddress)
        external
        view
        returns (bool syndicateDeployerIsActive);

    function getSyndicateTokenLaunchTimeUsingAddress(address checkAddress)
        external
        view
        returns (uint256 syndicateLaunchTime);
}

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

import {IERC721} from "../../lib/openzepplin-contracts/contracts/token/ERC721/IERC721.sol";

/// @title Syndicate Ecosystem Registry Interface
/// @notice Interface definition for Registry of all deployed urbit Syndicate Tokens
/// @custom:author ~sarlev-sarsen -- DM on the urbit network for further details

interface ISyndicateRegistry is IERC721 {
    /////////////
    // Structs //
    /////////////

    /// @title Syndicate Deployer Data Structure
    /// @notice Struct for data about Syndicate Deployer contract to be stored in an array in the Registry contract
    /// @dev This struct is deliberately general purpose in order to support variability in future deployer types and functionality.
    /// @dev Deployer contracts are given the permissions to modify the state of the registry and should therefore be closely monitored in order to prevent compromise of the registry as a whole
    struct SyndicateDeployerData {
        /// @notice The address of a deployer contract
        /// @dev Deliberately takes any address to leave optionality for implementation details and interface updates of future SyndicateDeployer contracts
        address deployerAddress; // 20 bytes
        /// @notice The version of a given deployer contract
        /// @dev Only one deplover of any given version should be deployed and recorded.
        /// @dev version numbers should be provided as major, minor, patch, with each taking 3 digits. I.e. version 1.2.3 would be encoded as `001.002.003` or `1002003`
        uint64 deployerVersion; // 8 bytes
        /// @notice The state of a given deployer contract
        /// @dev Inactive deployers should not be able to launch additional Syndicate Token Contracts, but should be able to change the ownership address of a given token.
        bool isActive; // 1 byte
    }

    /// @title Syndicate Data Structure
    /// @notice Struct for data about Syndicate token contracts to be stored in a mapping in the Syndicate Registry contract
    /// @dev Designed as a relatively open ended datastructure for referencing deployed contracts to enable flexible future Syndicate Deployer implementations with additional features
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

    ////////////
    // Events //
    ////////////

    //////////////////////////////////
    //// Deployer Contract Events ////
    //////////////////////////////////

    /// @notice Emitted when a deployer is added to the registry
    /// @dev Deployers are limited enough to also be stored in an array which can be more readily queried than a mapping
    /// @param syndicateDeployer The address of the newly registered Deployer
    /// @param deployerVersion The version number of the deployer, see {SyndicateDeployerData} struct for version number encoding details
    /// @param isActive The registration eligibility of the deployer, should be true on initial registration
    event DeployerRegistered(address indexed syndicateDeployer, uint64 indexed deployerVersion, bool isActive);

    /// @notice Emitted when a deployer is deactivated on the registry
    /// @dev Deativation of a deployer sets isActive to false, but retains data in contract storage for reference purposes
    /// @param syndicateDeployer The deployer contract address
    /// @param isActive The registration eligibility of the deployer, should be false on deactivation
    event DeployerDeactivated(address indexed syndicateDeployer, bool isActive);

    /// @notice Emitted when a deployer is activated on the registry
    /// @dev Activation of a deployer sets isActive to true
    /// @param syndicateDeployer The deployer contract address
    /// @param isActive The registration eligibility of the deployer, should be true on activation
    event DeployerReactivated(address indexed syndicateDeployer, bool isActive);

    /////////////////////////////////
    //// Syndicate Contract Events //
    /////////////////////////////////

    /// @notice Emitted when a new syndicate token is properly registered
    /// @dev While the deployer and token addresses are immutable, the owner address is subject to change following event emission. Do not assume ownership address to continue to control the token contract, rather query the `getOwner()` function of the token contract for the most up to date ownership permissions
    /// @param deployerAddress The contract address of the SyndicateDeployer used to deploy the Syndicate Token
    /// @param syndicateToken The contract address of the newly registered token
    /// @param owner The ownership address of the newly registered token
    /// @param azimuthPoint The tokenId of the urbit ID associated with the Syndicate Token
    event SyndicateRegistered(
        address indexed deployerAddress, address indexed syndicateToken, address owner, uint256 indexed azimuthPoint
    );

    /// @notice Emitted when a syndicate owner removes the token from the ecosystem registry
    /// @dev Listen for this event to remove contracts from interfaces and other user-facing tools. Note, removing a Syndicate from the registry does not *fully* disable the ERC20 contract functionality, i.e. the transfer function will continue to operate.
    /// @param deployerAddress The contract address of the SyndicateDeployer used to deploy the Syndicate Token
    /// @param syndicateToken The contract address of the token removed from the registry
    /// @param owner The ownership address of the newly registered token
    /// @param azimuthPoint The tokenId of the urbit ID associated with the Syndicate Token
    event SyndicateDissolved(
        address indexed deployerAddress, address indexed syndicateToken, address owner, uint256 indexed azimuthPoint
    );

    /// @notice Emitted when a syndicate token owner is successfully updated
    /// @dev The owner address emitted here MUST be confirmed to be a valid TBA for the syndicate token's azimuth point
    /// @param deployerAddress The address of the deployer associated with the updated syndicate token
    /// @param syndicateToken The token contract address which just had it's owner updated
    /// @param owner The address of the new owner of the token contract
    /// @param azimuthPoint The tokenId of the urbit ID associated with the Syndicate Token
    event SyndicateOwnerUpdated(
        address indexed deployerAddress, address indexed syndicateToken, address owner, uint256 indexed azimuthPoint
    );

    //////////////////////////
    //// Ownership Events ////
    //////////////////////////

    /// @notice Emitted when an ecosystem ownership transfer is proposed
    /// @param pendingOwner The proposed new owner for the registry contract
    /// @param registryOwner The current owner of the registry contract
    event OwnerProposed(address indexed pendingOwner, address indexed registryOwner);

    /// @notice Emitted when ownership transfer is accepted
    /// @param previousOwner The old owner of the registry contract
    /// @param newOwner The new owner of the registry contract
    event OwnerUpdated(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the ownership transfer is rejected by pendingOwner
    /// @param proposedOwner The address that rejected ownership control of the registry
    /// @param retainedOwner The address that retains ownership control of the registry
    event OwnershipRejected(address indexed proposedOwner, address indexed retainedOwner);

    /// @notice Emitted when the owner nullifies the proposed ownership transfer
    /// @dev
    /// @param registryOwner The address which owns the registry contract
    /// @param proposedOwner The address removed from proposed owner role
    event ProposalNullified(address indexed registryOwner, address indexed proposedOwner);

    /// @notice Emitted when the owner permanently renounced ownership to the null address
    /// @dev
    /// @param previousOwner The address that ultimately renounced ownership of the registry
    event OwnershipRenounced(address indexed previousOwner);

    ////////////////////////
    // External Functions //
    ////////////////////////

    ///////////////////////////////////////
    //// Deployer management functions ////
    ///////////////////////////////////////

    /// @notice Called to add a new deployer to the Syndicate Registry
    /// @dev This function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been added to the registry
    function registerDeployer(SyndicateDeployerData calldata syndicateDeployerData) external returns (bool success);

    /// @notice Called to deactivate deployer in the Syndicate Registry
    /// @dev This function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been deactivated in the registry
    function deactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData) external returns (bool success);

    /// @notice Called to reactivate deployer in the Syndicate Registry
    /// @dev This function should be restricted to onlyOwner
    /// @param syndicateDeployerData See {SyndicateDeployerData} for struct documentation
    /// @return success The confirmation that the deployer has been reactivated in the registry
    function reactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData) external returns (bool success);

    //////////////////////////////////////
    //// Syndicate registry functions ////
    //////////////////////////////////////

    /// @notice Called by an active Syndicate Deployer to launch a Syndicate Token
    /// @dev This function should only be callable by an active Syndicate Deployer, and the syndicate deployer MUST implement the check to ensure only a valid TBA may register a syndicate and create a mapping(uint256 => Syndicate) in the process.
    /// @param syndicate See {Syndicate} for struct documentation
    /// @return success Boolean for transaction completion
    function registerSyndicate(Syndicate calldata syndicate) external returns (bool success);

    /// @notice Called by a syndicate deployer to dissove a Syndicate Token's association with the registry
    /// @dev This function should only be callable by a Syndicate Deployer
    /// @param syndicate See {Syndicate} for struct documentation
    /// @return success Boolean for transaction completion
    function dissolveSyndicate(Syndicate calldata syndicate) external returns (bool success);

    /// @notice Called by an active syndicate deployer to update the owner of a Syndicate token contract
    /// @dev should only be callable by an active Syndicate Deployer, and the syndicate deployer MUST implement the check to ensure only a valid TBA may be made the owner of a given syndicate, updating the mapping(uint256 => Syndicate) in the process.
    /// @param syndicateToken The address of the syndicate token contract
    /// @param newOwner The address of the proposed new owner of the syndicateToken contact
    /// @return success Boolean for transaction completion
    function updateSyndicateOwnerRegistration(address syndicateToken, address newOwner)
        external
        returns (bool success);

    //////////////////////////////////////
    //// Ownership transfer functions ////
    //////////////////////////////////////

    /// @notice called calldata by Syndicate Registry owner to propose new ownership keys
    /// @dev should only be callable by current contract owner
    /// @param proposedOwner The address of the proposed new owner
    /// @return success Boolean for transaction completion
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

    /// @notice getter function to check if a syndicate token exists for a given Azimuth Point
    /// @dev this checks if there is a Syndicate Token currently registered; it does not return true if a syndicate has been launched but dissolved.
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateExists A boolean indicating if a syndicate token exists
    function getSyndicateTokenExistsUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (bool syndicateExists);

    /// @notice Getter function to retrieve the token address of a given Azimuth Point
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateAddress The address of a Syndicate Token; if it returns the null address, there is no registered Syndicate for the provided Urbit ID
    function getSyndicateTokenAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateAddress);

    /// @notice Getter function to retrieve the ownership address of an Azimuth Point
    /// @dev This will return an address which is associated with the Urbit ID as an ERC6551 account, but makes no validation checks about the security implications or smart contract wallet functionality of the implementation being used by the Azimuth Point's owner
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateOwner The current address with ownership rights over the Syndicate Token associated with the provided Urbit ID
    function getSyndicateTokenOwnerAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateOwner);

    /// @notice Getter function to retrieve the deployer used to launch a syndicate token
    /// @dev Will return the null address if no syndicate token has been launched by the provided Azimuth Point
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateDeployerAddress The address of the deployer contract used to launch the associated token
    function getSyndicateTokenDeployerAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateDeployerAddress);

    /// @notice Getter function to retrieve the version number of the deployer used for a given Azimuth Point's Syndicate token
    /// @dev See the {SyndicateDeployerData} struct for details on version number encoding
    /// @dev will return zero for an unlaunched Syndicate Token
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateDeployerVersion The encoded version number
    function getSyndicateTokenDeployerVersionUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (uint64 syndicateDeployerVersion);

    /// @notice Getter function to check if the deployer used to launch is still active
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateDeployerIsActive The boolean indicating if the deployer is active
    function getSyndicateTokenDeployerIsActiveUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (bool syndicateDeployerIsActive);

    /// @notice Getter function to check blockheight of token launch
    /// @dev If it returns 0, a token has either not been launched, or has been disolved.
    /// @param azimuthPoint The tokenId of an Urbit ID
    /// @return syndicateLaunchTime The block height at which the syndicate for the urbit ID was launched
    function getSyndicateTokenLaunchTimeUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (uint256 syndicateLaunchTime);

    /// @notice Getter function to check if a provided address is a registered Syndicate Token
    /// @param checkAddress An address to check against the registry for presence of an associated Urbit ID
    /// @return syndicateExists The boolean indicating if a Syndicate Token exists at a given address
    function getSyndicateTokenExistsUsingAddress(address checkAddress) external view returns (bool syndicateExists);

    // TODO Check how we are handling the ~zod / 0 / null return
    /// @notice Getter function to retrieve an azimuth point if it is associated with the provided address
    /// @dev should revert if there is no syndicate, as returning the default value, 0, should only occur if the address is associated with ~zod's Syndicate Token
    /// @param checkAddress The address to check in the registry for association with an Urbit ID
    /// @return azimuthPoint The tokenId of the Urbit ID that owns the Syndicate Token at the provided address
    function getSyndicateAzimuthPointUsingAddress(address checkAddress) external view returns (uint256 azimuthPoint);

    /// @notice Get the full {Syndicate} struct for a given address
    /// @param checkAddress A suspected Syndicate Token address
    /// @return someSyndicate A {Syndicate} struct for the provided address, if it exists
    function getSyndicateUsingTokenAddress(address checkAddress)
        external
        view
        returns (Syndicate memory someSyndicate);

    /// @notice Get the ownership address for a provided Syndicate Token
    /// @param checkAddress A suspected Syndicate Token address
    /// @return syndicateOwner The address which controls the ownership rights for the provided Syndicate Token
    function getSyndicateTokenOwnerAddressUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateOwner);

    /// @notice Get the deployer address for a provided Syndicate Token
    /// @param checkAddress A suspected Syndicate Token address
    /// @return syndicateDeployerAddress The address of the deployer used to launch the Syndicate Token
    function getSyndicateTokenDeployerAddressUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateDeployerAddress);

    /// @notice Get the deployer version for a provided Syndicate Token
    /// @param checkAddress A suspected Syndicate Token address
    /// @return syndicateDeployerVersion The deployer version used to launch the Syndicate Token
    function getSyndicateTokenDeployerVersionUsingAddress(address checkAddress)
        external
        view
        returns (uint64 syndicateDeployerVersion);

    /// @notice Get the deployer active state for a provided Syndicate Token
    /// @param checkAddress A suspected Syndicate Token address
    /// @return syndicateDeployerIsActive The boolean indicating deployer active state
    function getSyndicateTokenDeployerIsActiveUsingAddress(address checkAddress)
        external
        view
        returns (bool syndicateDeployerIsActive);

    /// Get the syndiate launch time for a provided Syndicate Token
    /// @param checkAddress A suspected Syndicate Token address
    /// @return syndicateLaunchTime The blockheight at which the given Syndicate Token was launched
    function getSyndicateTokenLaunchTimeUsingAddress(address checkAddress)
        external
        view
        returns (uint256 syndicateLaunchTime);
}

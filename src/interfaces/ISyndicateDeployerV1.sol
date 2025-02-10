// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

/// @title Interface for Syndicate Deployer
/// @author @thelifeandtimes
/// @notice deploys syndicate tokens associated with onchain Urbit identities
/// @dev dm ~sarlev-sarsen on urbit for details
interface ISyndicateDeployerV1 {
    // Events
    /// @notice emitted when Deployer is created
    /// @dev
    /// @param registryAddress The immutable registry address to which the deployer will be added
    /// @param fee The protocol fee rate applied to token contracts launched from this deployer
    /// @param feeRecipient The address to recieve protocol fees from deployed token contracts
    event DeployerV1Deployed(
        address indexed registryAddress,
        uint256 fee,
        address feeRecipient
    );

    /// @notice emitted when a new token is deployed
    /// @dev
    /// @param token The syndicate token contract address
    /// @param owner The address associated with Urbit ID that launched token
    /// @param azimuthPoint The Urbit ID associated with the Syndicate Token
    event TokenDeployed(
        address indexed token,
        address indexed owner,
        uint256 indexed azimuthPoint
    );

    /// @notice emitted when a syndicate token contract's owner changes
    /// @dev
    /// @param token The syndicate token contract address
    /// @param newOwner The address of the new owner, which should be a valid TBA
    event TokenOwnerChanged(address indexed token, address newOwner);

    /// @notice emitted when owner updates the fee percentage
    /// @dev
    /// @param fee The minting fee as percentage
    event FeeUpdated(uint256 fee);

    /// @notice emitted when the protocol fee recipient is updated
    /// @dev
    /// @param feeRecipient The address to recieve protocol fees
    event FeeRecipientUpdated(address feeRecipient);

    // TODO add natspec
    event PermissionedContractAdded(address permissionedContract);

    // TODO add natspec
    event PermissionedContractRemoved(address permissionedContract);

    // TODO add natspec
    event AzimuthPointAddedToWhitelist(uint256 azimuthPoint);

    // TODO add natspec
    event AzimuthPointRemovedFromWhitelist(uint256 azimuthPoint);

    // TODO add natspec
    event BetaModeChanged(bool betaMode);

    // TODO add natspec

    event AddedTbaImplementation(
        address tbaImplementationAddress,
        address deployerOwner
    );

    // TODO add natspec
    event RemovedTbaImplementation(
        address tbaImplementationAddress,
        address deployerOwner
    );

    // TODO add natspec
    event ExternalCallAttempted(address indexed target, bytes data);

    // TODO add natspec
    event ExternalCallExecuted(
        address indexed target,
        bytes data,
        bool success
    );

    // Errors
    // TODO Add natspec
    // error Unauthorized();

    // Functions
    /// @notice Called to deploy a syndicate token
    /// @dev The implemnentation address and salt can take any value, but interfaces should provide helpful tracking and management for end users, lest an address be set up and not recorded by the user, making recovery of control or funds difficult, although possible via replaying of events.
    /// @dev name and symbol parameters have no hard enforcement, but may benefit from default values in the user interface that draw from the related azimuthPoint
    /// @param implementation The implementation address for an IERC6551Account and it's associated logic
    /// @param salt Any valid bytes32, but default is expected to be `bytes32(0)`
    /// @param initialSupply The initial mint value to be created and sent to msg.sender
    /// @param maxSupply The hard cap on the ERC20 supply; set to type(uint256).max for unlimited supply
    /// @param azimuthPoint The tokenId / @ud of the associated Urbit ID
    /// @param name The token name per ERC20 standard
    /// @param symbol The token symbol per ERC20 standard
    /// @return syndicateToken The token contract address just deployed
    function deploySyndicate(
        address implementation,
        bytes32 salt,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 azimuthPoint,
        string memory name,
        string memory symbol
    ) external returns (address syndicateToken);

    /// @notice Called to update the ownership address of a syndicate token contract
    /// @dev Should be restricted to only being called by existing syndicate token contracts, and should implement a validation check on the newOwner being a derived Tokenbound Account of the syndicate's azimuthPoint.
    /// @dev Expected to call out to the Syndicate Registry contract to update the mapping of a given syndicate.
    /// @param newOwner The address of the new owner for the syndicate contract to be validated against the ERC6551Registry account() function
    /// @param azimuthPoint The @ud / tokenId of the Urbit Id associated with the syndicate token contract, used in ownership address validation
    /// @param implementation The address of a IERC6551Account compliant contract
    /// @param salt The bytes32 value of some salt, by default `bytes32(0)` should be used
    /// @return success The boolean which should indicate that the input parameters were all validated, the registry was updated, and the syndcate contract owner was updated
    function registerTokenOwnerChange(
        address newOwner,
        uint256 azimuthPoint,
        address implementation,
        bytes32 salt
    ) external returns (bool success);

    /// @notice Called to change protocol fee
    /// @dev function should be restricted to onlyOwner
    /// @param fee The fee percentage
    function changeFee(uint256 fee) external;

    /// @notice called to update the feeRecipient address
    /// @dev
    /// @param newFeeRecipient The address to recieve token distribution fee
    /// @return success The confirmation of the address being updated
    function changeFeeRecipient(
        address newFeeRecipient
    ) external returns (bool success);

    // TODO add natspec
    function toggleBetaMode(bool betaState) external returns (bool success);

    // TODO add natspec
    function addApprovedTbaImplementation(
        address contractAddress
    ) external returns (bool success);

    // TODO add natspec
    function removeApprovedTbaImplementation(
        address contractAddress
    ) external returns (bool success);

    // TODO add natspec
    function addWhitelistedPoint(
        uint256 azimuthPoint
    ) external returns (bool success);

    // TODO add natspec
    function batchWhitelistPoints(
        uint256[] calldata azimuthPoint
    ) external returns (bool success);

    // TODO add natspec
    function removeWhitelistedPoint(
        uint256 azimuthPoint
    ) external returns (bool success);

    // TODO add natspec
    function addPermissionedContract(
        address contractAddress
    ) external returns (bool success);

    // TODO add natspec
    function removePermissionedContract(
        address contractAddress
    ) external returns (bool success);

    // TODO add natspec
    function dissolveSyndicateInRegistry(
        uint256 azimuthPoint
    ) external returns (bool success);

    // TODO add natspec
    function executeCall(
        address target,
        bytes calldata data
    ) external returns (bool success, bytes memory result);

    /// @notice called to get address of registry contract
    /// @dev
    /// @return syndicateRegistry The address of the registry contract which implements the ISyndicateRegistry interface
    function getRegistry() external view returns (address syndicateRegistry);

    /// @notice Called to get the owner of the deployer contract
    /// @dev The default implementation of this refences the owner of the Syndicate Registry contract
    /// @return deployerOwner The address which can change the protocol fee and fee recipient
    function getOwner() external view returns (address deployerOwner);

    /// @notice Called to get the pending owner of the deployer contract
    /// @dev The default implementation of this refences the pending owner of the Syndicate Registry contract
    /// @return proposedOwner The address which is next in line to take over ownership of the deployer contract
    function getPendingOwner() external view returns (address proposedOwner);

    /// @notice Called to get the recipient of protocol fees generated by syndicate token contracts
    /// @dev
    /// @return feeRecipient The payment address for protocol fees
    function getFeeRecipient() external view returns (address feeRecipient);

    /// @notice Called to get the fee rate to be applied to launched Syndicate Token contracts
    /// @dev
    /// @return fee The percentage fee rate with a default 18 decimal places
    function getFee() external view returns (uint256 fee);

    // TODO add natspec
    function getDeployerStatus() external view returns (bool isActive);

    // TODO add natspec
    function checkIfPermissioned(
        address contractAddress
    ) external view returns (bool isPermissioned);

    // TODO add natspec
    function isRelatedSyndicate(
        address contractAddress
    ) external view returns (bool isRelated);

    // TODO add natspec
    function inBetaMode() external view returns (bool betaState);

    // TODO add natspec
    function isApprovedImplementation(
        address checkAddress
    ) external view returns (bool approvedImplementation);
}

// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.25;

/// @title Interface for Syndicate Deployer
/// @notice Interface definition of V1 contract for deploying syndicate tokens associated with onchain Urbit identities
/// @custom:author ~sarlev-sarsen -- DM on the urbit network for further details

interface ISyndicateDeployerV1 {
    ////////////
    // Events //
    ////////////

    /// @notice Emitted when Deployer is created
    /// @dev
    /// @param registryAddress The immutable registry address to which the deployer will be added
    /// @param fee The protocol fee rate applied to token contracts launched from this deployer
    /// @param feeRecipient The address to recieve protocol fees from deployed token contracts
    event DeployerV1Deployed(
        address indexed registryAddress,
        uint256 fee,
        address indexed feeRecipient
    );

    /// @notice Emitted when a new token is deployed
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
    /// @param newFee The minting fee as percentage using basis points
    /// @param updateBlockheight The actual blockheight of the change
    event FeeUpdated(uint256 newFee, uint256 updateBlockheight);

    /// @notice Emitted when the owner proposed a change to the protocol fee rate
    /// @dev Multiple may be emitted in a row, the most recent overwrite older values even if the fee is not updated
    event FeeRateChangeProposed(
        uint256 newFee,
        uint256 updateBlockheight,
        address indexed changeProposer
    );

    /// @notice emitted when the protocol fee recipient is updated
    /// @dev
    /// @param feeRecipient The address to recieve protocol fees
    event FeeRecipientUpdated(address indexed feeRecipient);

    /// @notice Emitted when a contract address is added to the deployer whitelist
    /// @dev As these are stored in a mapping, in order to track the full set of permissioned contracts, you must follow all events from the contract
    /// @param permissionedContract The address of the contract added to the whitelist
    event PermissionedContractAdded(address indexed permissionedContract);

    /// @notice Emitted when a contract address is removed from the deployer whitelist
    /// @dev As these are stored in a mapping, in order to track the full set of permissioned contracts, you must follow all events from the contract
    /// @param permissionedContract The address of the contract removed from the whitelist
    event PermissionedContractRemoved(address indexed permissionedContract);

    /// @notice Emitted when an Urbit ID is added to the beta whitelist
    /// @param azimuthPoint The tokenId of the Azimuth point added to the whitelist
    event AzimuthPointAddedToWhitelist(uint256 indexed azimuthPoint);

    /// @notice Emitted when an Urbit ID is removed from the beta whitelist
    /// @param azimuthPoint The tokenId of the Azimuth point removed from the whitelist
    event AzimuthPointRemovedFromWhitelist(uint256 indexed azimuthPoint);

    /// @notice Emitted when the beta mode is changed
    /// @dev If the beta mode is true, an Urbit ID's azimuth point must be in the whitelist in order to launch a Syndicate Token
    /// @param betaMode The state of the beta mode
    event BetaModeChanged(bool betaMode);

    /// @notice Emitted when a TBA implementation address is added to the approved list
    /// @dev This should remain a very limited list as implementations must be vetted to ensure their signature validation and signing controls are actually limited to the owner of the Urbit ID that is associated with them according to the ERC6551 Registry `account()` function.
    /// @param tbaImplementationAddress The address of a tokenbound account implementation
    /// @param deployerOwner The address of the deployer owner that called the function to add the implementation
    event AddedTbaImplementation(
        address indexed tbaImplementationAddress,
        address indexed deployerOwner
    );

    /// @notice Emitted when a TBA implementation address is removed from the approved list
    /// @dev This should remain a very limited list as implementations must be vetted to ensure their signature validation and signing controls are actually limited to the owner of the Urbit ID that is associated with them according to the ERC6551 Registry `account()` function.
    /// @param tbaImplementationAddress The address of a tokenbound account implementation
    /// @param deployerOwner The address of the deployer owner that called the function to remove the implementation
    event RemovedTbaImplementation(
        address indexed tbaImplementationAddress,
        address indexed deployerOwner
    );

    /// @notice Emitted when an attempt is made by the deployer to dissolve a Syndicate
    /// @dev Should be one of three dissolution related events, one from each of the registry, deployer, and token contracts
    /// @param azimuthPoint The tokenId of the Urbit ID associated with the Syndicate Token to be dissolved
    /// @param syndicateToken The contract address of the syndicateToken to be dissolved, which should also be the function caller
    event DissolutionRequestSentToRegistry(
        uint256 indexed azimuthPoint,
        address indexed syndicateToken
    );

    ////////////////////////
    // External functions //
    ////////////////////////

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
    /// @return success The boolean which should indicate that the input parameters were all validated, the registry was updated, and the syndicate contract owner was updated
    function registerTokenOwnerChange(
        address newOwner,
        uint256 azimuthPoint,
        address implementation,
        bytes32 salt
    ) external returns (bool success);

    /// @notice Propose a change to the protocol fee for newly launched Syndicate Tokens
    /// @dev Target delay must be greater than 6600 blocks, approximately 1 day
    /// @param proposedFee The fee amount in basis points, i.e. 300 is a 3% fee
    /// @param targetDelay The time between proposal and earliest activation date, in blocks
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function proposeFeeChange(
        uint256 proposedFee,
        uint256 targetDelay
    ) external returns (bool success);

    /// @notice Called to change protocol fee
    /// @dev function should be restricted to onlyOwner
    /// @return success The boolean which should indicate that the fee change was successful
    function changeFee() external returns (bool success);

    /// @notice called to update the feeRecipient address
    /// @dev
    /// @param newFeeRecipient The address to recieve token distribution fee
    /// @return success The confirmation of the address being updated
    function changeFeeRecipient(
        address newFeeRecipient
    ) external returns (bool success);

    /// @notice Toggle beta mode to enforce whitelisted azimuthPoints
    /// @dev When true, only tokenIds in the whitelist mapping will be able to launch Syndicate Tokens
    /// @param betaState The boolean value for the desired beta state
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function toggleBetaMode(bool betaState) external returns (bool success);

    /// @notice Add approved Tokenbound account implementation
    /// @dev Approved implementations are only used for initial deployment check; Syndicate Owners may use *any* implementation following initial launch
    /// @dev As approved implementations are stored in a mapping, track event emissions to collate the full state of the whitelist
    /// @param contractAddress The address of an approved Tokenbound Account implementation which has been vetted to only allow control by the TokenId owner
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function addApprovedTbaImplementation(
        address contractAddress
    ) external returns (bool success);

    /// @notice Remove approved Tokenbound account implementation
    /// @dev Approved implementations are only used for initial deployment check; Syndicate Owners may use *any* implementation following initial launch
    /// @dev As approved implementations are stored in a mapping, track event emissions to collate the full state of the whitelist
    /// @param contractAddress The address of a Tokenbound Account implementation to be removed from the whitelist
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function removeApprovedTbaImplementation(
        address contractAddress
    ) external returns (bool success);

    /// @notice Add an Azimuth Point to the beta whitelist
    /// @param azimuthPoint The tokenId of an Urbit ID to be added to the whitelist
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function addWhitelistedPoint(
        uint256 azimuthPoint
    ) external returns (bool success);

    /// @notice Add an array of Azimuth Points to the beta whitelist
    /// @param azimuthPoint The tokenId of an Urbit ID to be added to the whitelist
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function batchWhitelistPoints(
        uint256[] calldata azimuthPoint
    ) external returns (bool success);

    /// @notice Remove an Azimuth Point from the beta whitelist
    /// @param azimuthPoint The tokenId of an Urbit ID to be removed from the whitelist
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function removeWhitelistedPoint(
        uint256 azimuthPoint
    ) external returns (bool success);

    /// @notice Add an address to the permissioned contract mapping
    /// @dev As permissioned contracts can do fee-less mints from Syndicate Token contracts, any contracts added here should be heavily vetted
    /// @dev As this adds contracts to a mapping, track event emissions to collate the full set of permissioned contracts
    /// @param contractAddress The address of a contract to be added to the permissionedContract mapping
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function addPermissionedContract(
        address contractAddress
    ) external returns (bool success);

    /// @notice Add an address to the permissioned contract mapping
    /// @dev As Syndicate Token's may be dependent on a permissioned contract for their minting functionality and related valuation, removals of permissioned contracts should be heavily vetted prior to execution
    /// @dev As this removes contracts to a mapping, track event emissions to collate the full set of permissioned contracts
    /// @param contractAddress The address of a contract to be removed from the permissionedContract mapping
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function removePermissionedContract(
        address contractAddress
    ) external returns (bool success);

    /// @notice Dissolve Syndicate in Registry
    /// @dev Should only be callable by the Syndicate associated with the azimuthPoint value being provided as an input parameter
    /// @param azimuthPoint The tokenId of the Syndicate to be removed from the registry
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function dissolveSyndicateInRegistry(
        uint256 azimuthPoint
    ) external returns (bool success);

    /// @notice called to get address of registry contract
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
    /// @dev This is also regularly called by individual Syndicate Token contracts during a mint to ensure fees go to the most updated recipeint address
    /// @return feeRecipient The payment address for protocol fees
    function getFeeRecipient() external view returns (address feeRecipient);

    /// @notice Called to get the fee rate to be applied to launched Syndicate Token contracts
    /// @return fee The percentage fee rate with a default 18 decimal places
    function getFee() external view returns (uint256 fee);

    /// @notice Gets the deployers activity status according to the Registry
    /// @return isActive The boolean indicating active status of SyndicateDeployerV1
    function getDeployerStatus() external view returns (bool isActive);

    /// @notice Earliest implementation block for proposed fee update`
    /// @return rateChangeBlockheight The blockheight at which `changeFee()` may be called by the owner
    function getRateChangeBlockheight()
        external
        view
        returns (uint256 rateChangeBlockheight);

    /// @notice Check if an address is a permissioned contract
    /// @param contractAddress Any address that may be in the permissioned contract mapping
    /// @return isPermissioned The boolean indicating permissioned status
    function isPermissionedContract(
        address contractAddress
    ) external view returns (bool isPermissioned);

    /// @notice Check if address is a Syndicate Token launched from this Deployer
    /// @param contractAddress Any address that may be a Syndicate Token
    /// @return isRelated The boolean indicating if address is a Syndicate Token from this deployer
    function isRelatedSyndicate(
        address contractAddress
    ) external view returns (bool isRelated);

    /// @notice Check state of Beta mode
    /// @return betaState The boolean indicating if deployer is in beta mode
    function inBetaMode() external view returns (bool betaState);

    /// @notice Check if address is an approved implementation
    /// @dev DM ~sarlev-sarsen on urbit to get your ERC6551 TBA implementation added as an approved implementation
    /// @param checkAddress The address of a potential tokenbound account implementation
    /// @return approvedImplementation The boolean indicating if the provided address is an approved implementation
    function isApprovedImplementation(
        address checkAddress
    ) external view returns (bool approvedImplementation);
}

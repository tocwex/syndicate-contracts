// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

import {ReentrancyGuard} from "../lib/openzepplin-contracts/contracts/security/ReentrancyGuard.sol";
import {SyndicateRegistry} from "./SyndicateRegistry.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {ISyndicateDeployerV1} from "./interfaces/ISyndicateDeployerV1.sol";
import {IERC6551Registry} from "../lib/tokenbound/lib/erc6551/src/interfaces/IERC6551Registry.sol";
import {IERC721} from "../lib/openzepplin-contracts/contracts/token/ERC721/IERC721.sol";

/// @title Syndicate Deployer Factory V1
/// @notice This is a contract factory and access management contract used to launch Syndicate Token contracts and mediate their registration and modification in the SyndicateRegistry contract
/// @notice The owner of the SyndicateDeployerV1 contract will always be the SyndicateRegistry owner, such that there is unified ownership of the Syndicate contract ecosystem
/// @custom:author ~sarlev-sarsen -- DM on the urbit network for further details

contract SyndicateDeployerV1 is ISyndicateDeployerV1, ReentrancyGuard {
    ///////////////////////
    // Storage Variables //
    ///////////////////////

    ///////////////////
    //// Constants ////
    ///////////////////

    /// @notice Contract address for ERC6551 Tokenbound Account Registry implementation
    /// @dev Address is generated using CREATE2 and is the cannonical multichain address
    IERC6551Registry private constant TBA_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

    /// @notice Number of blocks used for timelocking fee changes
    /// @dev The 6600 number is approximately 1 day
    uint256 private constant MIN_FEE_TIMELOCK = 6600;

    ////////////////////
    //// Immutables ////
    ////////////////////

    /// @notice contract address for Syndicate Registry singleton
    ISyndicateRegistry private immutable i_registry;

    /// @notice contract address for deriving ownership of Azimuth Points / Urbit IDs
    // TODO Look into the questions around impacts of ecliptic.eth self-destructing?
    IERC721 private immutable i_azimuthContract;

    /////////////////////////////////
    //// Regular State Variables ////
    /////////////////////////////////

    /// @notice Address of recipient of protocol fees for Syndicate Tokens launched from this deployer
    /// @dev Updates to this address will impact the recipient for all future mints of any Syndicate Tokens launched from this contract
    address private _feeRecipient;

    /// @notice The protocol fee rate
    /// @dev The fee rate is used in the contructor of SyndicateTokenV1 contracts to set the max fee; it can only be reduced from there, and can be reduced on a case-by-case basis.
    uint256 private _feeRate;

    /// @notice A proposed updated amount for the fee rate
    uint256 private _proposedFeeRate;

    /// @notice The blockheight at which a new fee is allowed to go into effect
    uint256 private _rateChangeBlockheight;

    /// @notice Boolean indicating if beta mode is on and the associated whitelist will be enforced
    bool private _betaMode = true;

    //////////////
    // Mappings //
    //////////////

    mapping(uint256 => bool) private _betaWhitelist;
    mapping(address => bool) private _deployedSyndicates;
    mapping(address => bool) private _permissionedContracts;
    mapping(address => bool) private _approvedImplementation;

    ///////////////
    // Modifiers //
    ///////////////

    /// @notice Access controls for functions only callable by the contract owner, the owner of the SyndicateRegistry contract
    modifier onlyOwner() {
        require(msg.sender == i_registry.getOwner(), "Unauthorized: Only registry owner");
        _;
    }

    /// @notice Access controls such that only Syndicate Deployers registered as 'active' in the SyndicateRegistry contract can launch new Syndicate Tokens
    modifier onlyActive() {
        bool deployerActive = _getDeployerStatus();
        require(deployerActive, "Inactive Deployer cannot launch Syndicate Token");
        _;
        deployerActive = _getDeployerStatus();
        require(deployerActive, "Deployer deactivated during launch attempt");
    }

    /// @notice Access control such that only Urbit IDs which do not have a syndicate entry in the SyndicateRegistry contract can launch new Syndicate Tokens
    modifier onlyUnlaunched(uint256 azimuthPoint) {
        require(azimuthPoint < 65535, "Only Stars and Galaxies can launch Syndicates from this deployer");
        bool isLaunched = i_registry.getSyndicateTokenExistsUsingAzimuthPoint(azimuthPoint);
        require(!isLaunched, "This syndicate already exists");
        _;
    }

    /// @notice Access controls such that only Syndicate Token's deployed from this deployer can call permissioned functions
    /// @dev SyndicateTokenV1 contracts have a limited set of functions they can use to call this contract, all of which must pass the Syndicate Token's Azimuth Point (the i_azimuthPoint value), thus enabling it can only modify storage pertaining to itself.
    modifier onlySyndicate(uint256 azimuthPoint) {
        require(_deployedSyndicates[msg.sender], "Unauthorized: Only syndicates launched from this deployer");
        uint256 checkAzimuthPoint = i_registry.getSyndicateAzimuthPointUsingAddress(msg.sender);
        require(checkAzimuthPoint == azimuthPoint, "Unauthorized: Only registered syndicates");
        _;
    }

    /// @notice Validation check that the provided parameters resolve appropriately as a TBA controlled by an Urbit ID
    modifier onlyValidTba(address proposedTbaAddress, uint256 azimuthPoint, address implementation, bytes32 salt) {
        require(azimuthPoint < 65535, "Only Stars and Galaxies can launch Syndicates from this deployer");
        address derivedTba =
            TBA_REGISTRY.account(implementation, salt, block.chainid, address(i_azimuthContract), azimuthPoint);
        require(proposedTbaAddress == derivedTba, "Proposed token owner not a valid TBA associated with Urbit ID");
        _;
    }

    /// @notice Validation check for if beta mode is on
    modifier onlyBetaMode() {
        require(_betaMode, "Function only valid if beta mode is on");
        _;
    }

    /////////////////
    // Constructor //
    /////////////////

    constructor(address registryAddress, address azimuthContract, uint256 fee) {
        require(registryAddress != address(0), "Registry address cannot be zero");
        require(azimuthContract != address(0), "Azimuth contract address cannot be zero");
        require(registryAddress.code.length > 0, "Registry must be a contract");
        require(azimuthContract.code.length > 0, "Azimuth must be a contract");
        require(fee <= 10000, "Protocol Fee may not be greater than 100%");

        i_registry = ISyndicateRegistry(registryAddress);
        i_azimuthContract = IERC721(azimuthContract);
        _feeRecipient = msg.sender;
        _feeRate = fee;
        emit DeployerV1Deployed({registryAddress: registryAddress, fee: fee, feeRecipient: msg.sender});
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    /// @inheritdoc ISyndicateDeployerV1
    function deploySyndicate(
        address implementation,
        bytes32 salt,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 azimuthPoint,
        string memory name,
        string memory symbol
    )
        external
        onlyActive
        onlyUnlaunched(azimuthPoint)
        onlyValidTba(msg.sender, azimuthPoint, implementation, salt)
        nonReentrant
        returns (address syndicateToken)
    {
        if (_betaMode) {
            require(_betaWhitelist[azimuthPoint], "Unauthorized: Urbit ID not on beta whitelist");
        }
        require(
            _approvedImplementation[implementation],
            "Unauthorized: initial deployment must occur from approved tokenbound implementation"
        );
        return _deploySyndicate(msg.sender, initialSupply, maxSupply, azimuthPoint, _feeRate, name, symbol);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function registerTokenOwnerChange(address newOwner, uint256 azimuthPoint, address implementation, bytes32 salt)
        external
        onlySyndicate(azimuthPoint)
        onlyValidTba(newOwner, azimuthPoint, implementation, salt)
        nonReentrant
        returns (bool success)
    {
        return _registerTokenOwnerChange(msg.sender, newOwner);
    }

    function proposeFeeChange(uint256 proposedFee, uint256 targetDelay) external onlyOwner returns (bool success) {
        require(targetDelay >= MIN_FEE_TIMELOCK, "Unauthorized: Proposed delay must be at least 6600 blocks");
        return _proposeFeeChange(proposedFee, targetDelay);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFee() external onlyOwner returns (bool success) {
        require(block.number >= _rateChangeBlockheight, "Unauthorized: Rate change still timelocked");
        require(_rateChangeBlockheight != 0, "Unauthorized: Fee must be proposed first");
        return _changeFee();
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFeeRecipient(address newFeeRecipient) external onlyOwner returns (bool success) {
        return _changeFeeRecipient(newFeeRecipient);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function toggleBetaMode(bool betaState) external onlyOwner returns (bool success) {
        return _toggleBetaMode(betaState);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function addApprovedTbaImplementation(address contractAddress) external onlyOwner returns (bool success) {
        return _addApprovedTbaImplementation(contractAddress);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function removeApprovedTbaImplementation(address contractAddress) external onlyOwner returns (bool success) {
        return _removeApprovedTbaImplementation(contractAddress);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function addWhitelistedPoint(uint256 azimuthPoint) external onlyOwner onlyBetaMode returns (bool success) {
        return _addWhitelistedPoint(azimuthPoint);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function batchWhitelistPoints(uint256[] calldata azimuthPoint)
        external
        onlyOwner
        onlyBetaMode
        returns (bool success)
    {
        return _batchWhitelistPoints(azimuthPoint);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function removeWhitelistedPoint(uint256 azimuthPoint) external onlyOwner onlyBetaMode returns (bool success) {
        return _removeWhitelistedPoint(azimuthPoint);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function addPermissionedContract(address contractAddress) external onlyOwner returns (bool success) {
        return _addPermissionedContract(contractAddress);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function removePermissionedContract(address contractAddress) external onlyOwner returns (bool success) {
        return _removePermissionedContract(contractAddress);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function dissolveSyndicateInRegistry(uint256 azimuthPoint)
        external
        onlySyndicate(azimuthPoint)
        nonReentrant
        returns (bool success)
    {
        return _dissolveSyndicateInRegistry(azimuthPoint);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getRegistry() external view returns (address syndicateRegistry) {
        return address(i_registry);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getOwner() external view returns (address deployerOwner) {
        return i_registry.getOwner();
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getPendingOwner() external view returns (address pendingOwner) {
        return i_registry.getPendingOwner();
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getFeeRecipient() external view returns (address feeRecipient) {
        return _feeRecipient;
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getFee() external view returns (uint256 fee) {
        return _feeRate;
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getDeployerStatus() external view returns (bool isActive) {
        return _getDeployerStatus();
    }

    /// @inheritdoc ISyndicateDeployerV1
    function getRateChangeBlockheight() external view returns (uint256 rateChangeBlockheight) {
        return _rateChangeBlockheight;
    }

    /// @inheritdoc ISyndicateDeployerV1
    function isPermissionedContract(address contractAddress) external view returns (bool isPermissioned) {
        return _permissionedContracts[contractAddress];
    }

    /// @inheritdoc ISyndicateDeployerV1
    function isRelatedSyndicate(address contractAddress) external view returns (bool isRelated) {
        return _deployedSyndicates[contractAddress];
    }

    /// @inheritdoc ISyndicateDeployerV1
    function inBetaMode() external view returns (bool betaState) {
        return _betaMode;
    }

    /// @inheritdoc ISyndicateDeployerV1
    function isApprovedImplementation(address checkAddress) external view returns (bool approvedImplementation) {
        return _approvedImplementation[checkAddress];
    }

    ////////////////////////////
    //// Internal Functions ////
    ////////////////////////////

    /// @notice Core functionality to deploy a Syndicate Token contract
    function _deploySyndicate(
        address tokenOwner,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 azimuthPoint,
        uint256 protocolFee,
        string memory name,
        string memory symbol
    ) internal returns (address tokenContract) {
        SyndicateTokenV1 syndicateTokenV1 = new SyndicateTokenV1(
            address(this), tokenOwner, initialSupply, maxSupply, azimuthPoint, protocolFee, name, symbol
        );

        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry.Syndicate({
            syndicateOwner: tokenOwner,
            syndicateContract: address(syndicateTokenV1),
            syndicateDeployer: address(this),
            syndicateLaunchTime: block.number,
            azimuthPoint: azimuthPoint
        });

        i_registry.registerSyndicate(syndicate);
        _deployedSyndicates[address(syndicateTokenV1)] = true;
        emit TokenDeployed({token: address(syndicateTokenV1), owner: tokenOwner, azimuthPoint: azimuthPoint});
        return address(syndicateTokenV1);
    }

    /// @notice Send token owner change info to registry
    /// @dev This function is responsible for updating ownership address info in the SyndicateRegistry
    function _registerTokenOwnerChange(address syndicateToken, address newOwner) internal returns (bool success) {
        success = i_registry.updateSyndicateOwnerRegistration(syndicateToken, newOwner);
        emit TokenOwnerChanged({token: syndicateToken, newOwner: newOwner});
        return success;
    }

    /// @notice Proposal of a fee change
    /// @dev Intention of the timelock is to prevent a malicious deployer owner from frontrunning a deployment and mint, thus charging more fees than intended to be allocated by the Syndicate Token owner
    /// @dev While the targetDelay value must be greater than 6600, it is best to use a larger delay and clearly communicate with users that fees will be increasing
    function _proposeFeeChange(uint256 proposedFee, uint256 targetDelay) internal returns (bool success) {
        _proposedFeeRate = proposedFee;
        _rateChangeBlockheight = targetDelay + block.number;
        success = true;

        emit FeeRateChangeProposed({
            newFee: proposedFee,
            updateBlockheight: _rateChangeBlockheight,
            changeProposer: msg.sender
        });

        return success;
    }

    /// @notice Trigger proposed fee change
    /// @dev Resets values set by proposeFeeChange to zero.
    function _changeFee() internal returns (bool success) {
        _feeRate = _proposedFeeRate;
        _rateChangeBlockheight = 0;
        _proposedFeeRate = 0;
        success = true;

        emit FeeUpdated({newFee: _feeRate, updateBlockheight: block.number});

        return success;
    }

    /// @notice Change fee recipient for Syndicate Tokens from this deployer
    /// @dev Changes the recipient of all future fees from any Syndicate Token launched from this deployer
    /// @dev Doesn't control 'permissionedMint` revenues, but permissionedContracts likely should point fee revenues towards the deployer fee recipient address
    function _changeFeeRecipient(address newFeeRecipient) internal returns (bool success) {
        _feeRecipient = newFeeRecipient;
        success = true;
        emit FeeRecipientUpdated({feeRecipient: newFeeRecipient});
        return success;
    }

    /// @notice Change beta mode state
    /// @dev Emits an event, but beta mode can also be queried directly using `inBetaMode()`
    function _toggleBetaMode(bool betaState) internal returns (bool success) {
        _betaMode = betaState;
        success = true;
        emit BetaModeChanged({betaMode: betaState});

        return success;
    }

    /// @notice Adds Tokenbound account implementation to approvedImplementation mapping
    /// @dev Track AddedTbaImplementation event to follow state of the approved addresses
    function _addApprovedTbaImplementation(address contractAddress) internal returns (bool success) {
        _approvedImplementation[contractAddress] = true;
        success = true;

        emit AddedTbaImplementation({tbaImplementationAddress: contractAddress, deployerOwner: msg.sender});

        return success;
    }

    /// @notice Removes Tokenbound account implementation from approvedImplementation mapping
    /// @dev Track RemovedTbaImplementation event to follow state of the approved addresses
    function _removeApprovedTbaImplementation(address contractAddress) internal returns (bool success) {
        _approvedImplementation[contractAddress] = true;
        success = true;

        emit RemovedTbaImplementation({tbaImplementationAddress: contractAddress, deployerOwner: msg.sender});

        return success;
    }

    /// @notice adds Urbit ID to the beta whitelist mapping
    /// @dev Track AzimuthPointAddedToWhitelist event to follow state of the approved Urbit IDs
    function _addWhitelistedPoint(uint256 azimuthPoint) internal returns (bool success) {
        _betaWhitelist[azimuthPoint] = true;
        success = true;

        emit AzimuthPointAddedToWhitelist({azimuthPoint: azimuthPoint});

        return success;
    }

    /// @notice Batch adds Urbit ID to the beta whitelist mapping
    /// @dev Track AzimuthPointRemovedFromWhitelist events to follow state of the approved Urbit IDs
    function _batchWhitelistPoints(uint256[] calldata azimuthPoint) internal returns (bool success) {
        require(azimuthPoint.length > 0, "Empty array");
        for (uint256 i = 0; i < azimuthPoint.length; i++) {
            _betaWhitelist[azimuthPoint[i]] = true;
            emit AzimuthPointAddedToWhitelist({azimuthPoint: azimuthPoint[i]});
        }
        success = true;

        return success;
    }

    /// @notice Removes Urbit ID from the beta whitelist mapping
    /// @dev Track AzimuthPointRemovedFromWhitelist event to follow state of the approved Urbit IDs
    function _removeWhitelistedPoint(uint256 azimuthPoint) internal returns (bool success) {
        _betaWhitelist[azimuthPoint] = false;
        success = true;

        emit AzimuthPointRemovedFromWhitelist({azimuthPoint: azimuthPoint});

        return success;
    }

    /// @notice Adds contract address to the permissioned contracts mapping
    /// @dev Track PermissionedContractAdded event to follow state of the approved addresses
    function _addPermissionedContract(address contractAddress) internal returns (bool success) {
        _permissionedContracts[contractAddress] = true;
        success = true;
        emit PermissionedContractAdded({permissionedContract: contractAddress});
        return success;
    }

    /// @notice Removes contract address from the permissioned contracts mapping
    /// @dev Track PermissionedContractRemoved event to follow state of the approved addresses
    function _removePermissionedContract(address contractAddress) internal returns (bool success) {
        _permissionedContracts[contractAddress] = false;
        success = true;
        emit PermissionedContractRemoved({permissionedContract: contractAddress});
        return success;
    }

    /// @notice Implementation logic to dissolve syndicate in registry
    /// @dev disolves a syndicate by wiping all values but azimuthPoint, which must remain non-zero as ~zod is the zeroth azimuthPoint
    function _dissolveSyndicateInRegistry(uint256 azimuthPoint) internal returns (bool success) {
        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry.Syndicate({
            syndicateOwner: address(0),
            syndicateContract: address(0),
            syndicateDeployer: address(0),
            syndicateLaunchTime: uint256(0),
            azimuthPoint: azimuthPoint
        });

        emit DissolutionRequestSentToRegistry({azimuthPoint: azimuthPoint, syndicateToken: msg.sender});
        success = i_registry.dissolveSyndicate(syndicate);
        _deployedSyndicates[msg.sender] = false;
        return success;
    }

    /// @notice Call to the registry contract for deployer to check it's approval state
    /// @dev A deployer must believe itself to be active in order to launch new Syndicate Tokens
    function _getDeployerStatus() internal view returns (bool isActive) {
        ISyndicateRegistry.SyndicateDeployerData memory syndicateDeployerData =
            i_registry.getDeployerData(address(this));
        return syndicateDeployerData.isActive;
    }

    /////////////////
    //// Receive ////
    /////////////////
    receive() external payable {
        revert("Direct ETH transfers not accepted");
    }

    //////////////////
    //// Fallback ////
    //////////////////
    fallback() external payable {
        revert("Function does not exist");
    }
}

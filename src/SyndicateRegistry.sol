// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO handle the way ~zod lookups / getters function to account for the default value of tokenId being 0, aka `@ud`~zod
import {ReentrancyGuard} from "../lib/openzepplin-contracts/contracts/security/ReentrancyGuard.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "./SyndicateDeployerV1.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";

/// @title Syndicate Ecosystem Registry Contract
/// @notice This is the primary registry contract for urbit's Syndicate ecosystem, designed to give a finite tokenspace for fungible tokens associated with urbit's finite address space and namespace
/// @custom:author ~sarlev-sarsen -- DM on the urbit network for further details

contract SyndicateRegistry is ISyndicateRegistry, ReentrancyGuard {
    ///////////////////////
    // Storage Variables //
    ///////////////////////

    ///////////////////
    //// Constants ////
    ///////////////////

    /////////////////////////////////
    //// Regular State Variables ////
    /////////////////////////////////

    address private _owner;
    address private _pendingOwner;
    address[] private _syndicateDeployers;

    //////////////
    // Mappings //
    //////////////

    /// @notice Registered Syndicate Deployer contract address
    /// @dev see ISyndicateRegistry {SyndicateDeployerData} struct for details
    /// @dev Key: address of the deployer contract
    /// @dev Value: Registered data of the deployer contract
    mapping(address => SyndicateDeployerData) private _deployerData;

    /// @notice Azimuth Point to registered SyndicateDeployerData
    /// @dev see ISyndicateRegistry {Syndicate} struct for details
    /// @dev Key: tokenId of the associated Urbit ID / Azimuth Point
    /// @dev Value: Registered data of the related Syndicate Token ERC20 contract
    mapping(uint256 => Syndicate) private _syndicate;

    /// @notice Registered Syndicate Token Contract address
    /// @dev Invalid addresses will return 0, as will ~zod's syndicate; if an address returns 0, check it against the Syndicte mapping
    /// @dev Key: Address of Syndicate Token ERC20 contract
    /// @dev Value: tokenId of the associated Urbit ID / Azimuth Point
    mapping(address => uint256) private _addressToAzimuthPoint;

    /// @notice Check if registered Syndicate Deployer
    /// @dev Key: Contract address of Syndicate Deployer
    /// @dev Value: Boolean returns true if provided address is a registered Syndicate Deployer contract
    mapping(address => bool) private _isRegisteredDeployer;

    /// @notice Check if active Syndicate Deployer
    /// @dev Inactive deployers cannot launch additional Syndicate token contracts
    /// @dev Key: Contract address of Syndicate Deployer
    /// @dev Value: Boolean returns true if provided address is a registered Syndicate Deployer contract
    mapping(address => bool) private _isActiveDeployer;

    ///////////////
    // Modifiers //
    ///////////////

    /// @notice Access controls for functions only callable by the contract owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized: Only registry owner");
        _;
    }

    /// @notice Access controls such that only a proposed owner may call fuctions protected by this modifier
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Unauthorized: Only Pending Owner");
        _;
    }

    /// @notice Access controls such that only a valid, aka 'registered' deployer may call functions protected by this modifier
    modifier onlyValidDeployer() {
        require(_isRegisteredDeployer[msg.sender], "Unauthorized: Only registered deployers");
        _;
    }

    /// @notice Access controls such that only a valid, and active, deployer may call functions protected by this modifier
    modifier onlyActiveDeployer() {
        require(_isActiveDeployer[msg.sender], "Unauthorized: Only active deployers");
        _;
    }

    /////////////////
    // Constructor //
    /////////////////

    constructor() {
        // constructor sets initial owner
        _owner = msg.sender;
    }

    ///////////////
    // Functions //
    ///////////////

    ////////////////////////////
    //// External Functions ////
    ////////////////////////////

    /// @inheritdoc ISyndicateRegistry
    function registerDeployer(SyndicateDeployerData calldata syndicateDeployerData)
        external
        onlyOwner
        returns (bool success)
    {
        return _registerDeployer(syndicateDeployerData);
    }

    /// @inheritdoc ISyndicateRegistry
    function deactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData)
        external
        onlyOwner
        returns (bool success)
    {
        return _deactivateDeployer(syndicateDeployerData);
    }

    /// @inheritdoc ISyndicateRegistry
    function reactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData)
        external
        onlyOwner
        returns (bool success)
    {
        return _reactivateDeployer(syndicateDeployerData);
    }

    /// @inheritdoc ISyndicateRegistry
    function registerSyndicate(Syndicate calldata syndicate)
        external
        onlyValidDeployer
        onlyActiveDeployer
        returns (bool success)
    {
        require(
            _syndicate[syndicate.azimuthPoint].syndicateContract == address(0),
            "Azimuth point already has active syndicate"
        );
        success = _registerSyndicate(syndicate);
        return success;
    }

    /// @inheritdoc ISyndicateRegistry
    function dissolveSyndicate(Syndicate calldata syndicate) external onlyValidDeployer returns (bool success) {
        require(
            syndicate.syndicateContract == address(0),
            "Dissolving a syndicate must set the token address to the null address"
        );

        success = _dissolveSyndicate(syndicate);

        return success;
    }

    /// @inheritdoc ISyndicateRegistry
    function updateSyndicateOwnerRegistration(address syndicateToken, address newOwner)
        external
        onlyValidDeployer
        returns (bool success)
    {
        return _updateSyndicateOwnerRegistration(syndicateToken, newOwner);
    }

    /// @inheritdoc ISyndicateRegistry
    function proposeNewOwner(address proposedOwner) external onlyOwner returns (bool success) {
        return _proposeNewOwner(proposedOwner);
    }

    /// @inheritdoc ISyndicateRegistry
    function acceptOwnership() external onlyPendingOwner returns (bool success) {
        return _acceptOwnership();
    }

    /// @inheritdoc ISyndicateRegistry
    function rejectOwnership() external onlyPendingOwner returns (bool success) {
        return _rejectOwnership();
    }

    /// @inheritdoc ISyndicateRegistry
    function nullifyProposal() external onlyOwner returns (bool success) {
        return _nullifyProposal();
    }

    /// @inheritdoc ISyndicateRegistry
    function renounceOwnership() external onlyOwner returns (bool success) {
        return _renounceOwnership();
    }

    /// @inheritdoc ISyndicateRegistry
    function getOwner() external view returns (address owner) {
        return _owner;
    }

    /// @inheritdoc ISyndicateRegistry
    function getPendingOwner() external view returns (address pendingOwner) {
        return _pendingOwner;
    }

    /// @inheritdoc ISyndicateRegistry
    function isRegisteredDeployer(address checkAddress) external view returns (bool isRegistered) {
        return _isRegisteredDeployer[checkAddress];
    }

    /// @inheritdoc ISyndicateRegistry
    function isActiveDeployer(address checkAddress) external view returns (bool isActive) {
        return _isActiveDeployer[checkAddress];
    }

    /// @inheritdoc ISyndicateRegistry
    function getDeployers() external view returns (address[] memory syndicateDeployers) {
        return _syndicateDeployers;
    }

    /// @inheritdoc ISyndicateRegistry
    function getDeployerData(address deployerAddress)
        external
        view
        returns (SyndicateDeployerData memory syndicateDeployerData)
    {
        return _deployerData[deployerAddress];
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenExistsUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (bool syndicateExists)
    {
        return _syndicate[azimuthPoint].syndicateContract != address(0);
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateAddress)
    {
        syndicateAddress = _syndicate[azimuthPoint].syndicateContract;
        return syndicateAddress;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenOwnerAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateOwner)
    {
        syndicateOwner = _syndicate[azimuthPoint].syndicateOwner;
        return syndicateOwner;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenDeployerAddressUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (address syndicateDeployerAddress)
    {
        return _syndicate[azimuthPoint].syndicateDeployer;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenDeployerVersionUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (uint64 syndicateDeployerVersion)
    {
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].deployerVersion;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenDeployerIsActiveUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (bool syndicateDeployerIsActive)
    {
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].isActive;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenLaunchTimeUsingAzimuthPoint(uint256 azimuthPoint)
        external
        view
        returns (uint256 syndicateLaunchTime)
    {
        return _syndicate[azimuthPoint].syndicateLaunchTime;
    }

    // TODO uint256 default value of 0 has some weird characteristics in how it relates to ~zod.
    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenExistsUsingAddress(address checkAddress) external view returns (bool syndicateExists) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return _syndicate[azimuthPoint].syndicateContract != address(0);
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateAzimuthPointUsingAddress(address checkAddress) external view returns (uint256 azimuthPoint) {
        azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return azimuthPoint;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateUsingTokenAddress(address checkAddress)
        external
        view
        returns (Syndicate memory someSyndicate)
    {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        someSyndicate = _syndicate[azimuthPoint];
        return someSyndicate;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenOwnerAddressUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateOwner)
    {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        syndicateOwner = _syndicate[azimuthPoint].syndicateOwner;
        return syndicateOwner;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenDeployerAddressUsingAddress(address checkAddress)
        external
        view
        returns (address syndicateDeployerAddress)
    {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return _syndicate[azimuthPoint].syndicateDeployer;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenDeployerVersionUsingAddress(address checkAddress)
        external
        view
        returns (uint64 syndicateDeployerVersion)
    {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].deployerVersion;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenDeployerIsActiveUsingAddress(address checkAddress)
        external
        view
        returns (bool syndicateDeployerIsActive)
    {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].isActive;
    }

    /// @inheritdoc ISyndicateRegistry
    function getSyndicateTokenLaunchTimeUsingAddress(address checkAddress)
        external
        view
        returns (uint256 syndicateLaunchTime)
    {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return _syndicate[azimuthPoint].syndicateLaunchTime;
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    /// @notice Core deployer registration function
    /// @dev Deployers cannot be unregistered, only deactivated
    function _registerDeployer(SyndicateDeployerData calldata syndicateDeployerData) internal returns (bool success) {
        require(syndicateDeployerData.deployerAddress != address(0), "Deployer is not at the null address");
        require(!_isRegisteredDeployer[syndicateDeployerData.deployerAddress], "Deployer is already registered");
        _syndicateDeployers.push(syndicateDeployerData.deployerAddress);
        _deployerData[syndicateDeployerData.deployerAddress] = syndicateDeployerData;
        _isRegisteredDeployer[syndicateDeployerData.deployerAddress] = true;
        _isActiveDeployer[syndicateDeployerData.deployerAddress] = true;

        emit DeployerRegistered(
            syndicateDeployerData.deployerAddress, syndicateDeployerData.deployerVersion, syndicateDeployerData.isActive
        );

        return true;
    }

    /// @notice Core deployer deactivation function
    function _deactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData)
        internal
        returns (bool success)
    {
        address deployer = syndicateDeployerData.deployerAddress;
        SyndicateDeployerData storage deployerData = _deployerData[deployer];
        require(_isRegisteredDeployer[deployer], "Deployer is not registered and thus cannot be deactivated");
        require(deployerData.isActive, "Deployer already inactive");
        deployerData.isActive = false;
        _isActiveDeployer[syndicateDeployerData.deployerAddress] = false;
        success = true;
        emit DeployerDeactivated(deployer, false);
        return success;
    }

    /// @notice Core deployer reactivation function
    function _reactivateDeployer(SyndicateDeployerData calldata syndicateDeployerData)
        internal
        returns (bool success)
    {
        address deployer = syndicateDeployerData.deployerAddress;
        SyndicateDeployerData storage deployerData = _deployerData[deployer];
        require(_isRegisteredDeployer[deployer], "Deployer is not registered and thus cannot be deactivated");
        require(!deployerData.isActive, "Deployer already active");
        deployerData.isActive = true;
        _isActiveDeployer[syndicateDeployerData.deployerAddress] = true;

        success = true;
        emit DeployerReactivated(deployer, true);
        return success;
    }

    /// @notice Core function for registering a Syndicate Token on launch
    /// @dev Callable only if no Syndicate Token yet exists
    function _registerSyndicate(Syndicate calldata syndicate) internal returns (bool success) {
        _syndicate[syndicate.azimuthPoint] = syndicate;
        _addressToAzimuthPoint[syndicate.syndicateContract] = syndicate.azimuthPoint;
        success = true;
        emit SyndicateRegistered({
            deployerAddress: msg.sender,
            syndicateToken: syndicate.syndicateContract,
            owner: syndicate.syndicateOwner,
            azimuthPoint: syndicate.azimuthPoint
        });
        return success;
    }

    /// @notice Functionality to update Syndicate ownership records in the registry
    /// @dev See {SyndicateOwnerUpdated} event for indexing info as only 3 parameters are able to be indexed
    function _updateSyndicateOwnerRegistration(address syndicateToken, address newOwner)
        internal
        returns (bool success)
    {
        uint256 syndicatePoint = _addressToAzimuthPoint[syndicateToken];
        _syndicate[syndicatePoint].syndicateOwner = newOwner;
        success = true;
        emit SyndicateOwnerUpdated({
            deployerAddress: msg.sender,
            syndicateToken: syndicateToken,
            owner: newOwner,
            azimuthPoint: syndicatePoint
        });
        return success;
    }

    /// @notice functionality for removing a Syndicate Token from the registry
    /// @dev Listen for these events in any interface that claims to index the existance of Syndicates
    function _dissolveSyndicate(Syndicate calldata syndicate) internal returns (bool success) {
        address deletedSyndicate = _syndicate[syndicate.azimuthPoint].syndicateContract;

        delete _addressToAzimuthPoint[deletedSyndicate];
        delete _syndicate[syndicate.azimuthPoint];

        success = true;
        emit SyndicateDissolved({
            deployerAddress: msg.sender,
            syndicateToken: syndicate.syndicateContract,
            owner: syndicate.syndicateOwner,
            azimuthPoint: syndicate.azimuthPoint
        });
        return success;
    }

    /// @notice Core functionality for proposing a new Syndicate contract ecosystem ownership address
    /// @dev Ownership control is recommended to be held by a multisig or other highly secure key management mechanism
    function _proposeNewOwner(address proposedOwner) internal returns (bool success) {
        _pendingOwner = proposedOwner;
        success = true;
        emit OwnerProposed({pendingOwner: proposedOwner, registryOwner: msg.sender});
        return success;
    }

    /// @notice Core functionality for accepting ecosystem ownership rights
    function _acceptOwnership() internal returns (bool success) {
        address previousOwner = _owner;
        address newOwner = _pendingOwner;
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit OwnerUpdated(previousOwner, newOwner);
        return success;
    }

    /// @notice Option for rejecting ownership rights offering by the proposed owner
    function _rejectOwnership() internal returns (bool success) {
        address retainedOwner = _owner;
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit OwnershipRejected(proposedOwner, retainedOwner);
        return success;
    }

    /// @notice Option for revoking ownership offering by current owner
    function _nullifyProposal() internal returns (bool success) {
        address retainedOwner = _owner;
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit ProposalNullified(retainedOwner, proposedOwner);
        return success;
    }

    /// @notice Core functionality for renouncing ecosystem ownership
    /// @dev Note that this is a destructive action which makes it impossible to register addtional deployer contracts. It may also make it impossible to take some permissioned actions on deployer contracts, such as fee rate modifications or more.
    function _renounceOwnership() internal returns (bool success) {
        address previousOwner = _owner;
        _owner = address(0);
        success = true;
        emit OwnershipRenounced(previousOwner);
        return success;
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

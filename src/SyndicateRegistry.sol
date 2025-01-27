// SPDX-License-Identifier: GPLv3

// TODO Implement reentrancy guards
// TODO implement function for accepting ENS name

pragma solidity ^0.8.19;

import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "./SyndicateDeployerV1.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";

contract SyndicateRegistry is ISyndicateRegistry {
    // State Variables
    address private _owner;
    address private _pendingOwner;
    address[] private _syndicateDeployers;

    // Mappings
    mapping(address => SyndicateDeployerData) private _deployerData; // Deployer address => deployer data
    mapping(uint256 => Syndicate) private _syndicate; // azimuthPoint => syndicate token contract struct
    mapping(address => uint256) private _addressToAzimuthPoint; // syndicate token address to azimuth point
    mapping(address => bool) private _isRegisteredDeployer; // check if address is a registered deployer

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Unauthorized");
        _;
    }

    modifier onlyValidDeployer() {
        require(_isRegisteredDeployer[msg.sender], "Unauthorized");
        _;
    }

    // Constructor
    constructor() {
        // constructor sets initial owner
        _owner = msg.sender;
    }

    // Functions
    //// Receive
    receive() external payable {
        revert("Direct ETH transfers not accepted"); // TK we could make this a donation to the registry owner?
    }

    //// Fallback
    fallback() external payable {
        revert("Function does not exist"); // TK we could make this a donation to the registry owner as well?
    }

    //// External Functions
    function registerDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external onlyOwner returns (bool success) {
        return _registerDeployer(syndicateDeployerData);
    }

    function deactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external onlyOwner returns (bool success) {
        return _deactivateDeployer(syndicateDeployerData);
    }

    function reactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external onlyOwner returns (bool success) {
        return _reactivateDeployer(syndicateDeployerData);
    }

    function registerSyndicate(
        Syndicate calldata syndicate
    ) external onlyValidDeployer returns (bool success) {
        return _registerSyndicate(syndicate);
    }

    function updateSyndicateOwnerRegistration(
        address syndicateToken,
        address newOwner
    ) external onlyValidDeployer returns (bool success) {
        return _updateSyndicateOwnerRegistration(syndicateToken, newOwner);
    }

    function proposeNewOwner(
        address proposedOwner
    ) external onlyOwner returns (bool success) {
        return _proposeNewOwner(proposedOwner);
    }

    function acceptOwnership()
        external
        onlyPendingOwner
        returns (bool success)
    {
        return _acceptOwnership();
    }

    function rejectOwnership()
        external
        onlyPendingOwner
        returns (bool success)
    {
        return _rejectOwnership();
    }

    function nullifyProposal() external onlyOwner returns (bool success) {
        return _nullifyProposal();
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        return _renounceOwnership();
    }

    function getOwner() external view returns (address owner) {
        return _owner;
    }

    function getPendingOwner() external view returns (address pendingOwner) {
        return _pendingOwner;
    }

    function isRegisteredDeployer(
        address checkAddress
    ) external view returns (bool isRegistered) {
        return _isRegisteredDeployer[checkAddress];
    }

    function getDeployers()
        external
        view
        returns (address[] memory syndicateDeployers)
    {
        return _syndicateDeployers;
    }

    function getDeployerData(
        address deployerAddress
    )
        external
        view
        returns (SyndicateDeployerData memory syndicateDeployerData)
    {
        return _deployerData[deployerAddress];
    }

    function getSyndicateTokenExistsUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (bool syndicateExists) {
        return _syndicate[azimuthPoint].syndicateContract != address(0);
    }

    function getSyndicateTokenAddressUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (address syndicateAddress) {
        syndicateAddress = _syndicate[azimuthPoint].syndicateContract;
        return syndicateAddress;
    }

    function getSyndicateTokenOwnerAddressUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (address syndicateOwner) {
        syndicateOwner = _syndicate[azimuthPoint].syndicateOwner;
        return syndicateOwner;
    }

    function getSyndicateTokenDeployerAddressUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (address syndicateDeployerAddress) {
        return _syndicate[azimuthPoint].syndicateDeployer;
    }

    function getSyndicateTokenDeployerVersionUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (uint64 syndicateDeployerVersion) {
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].deployerVersion;
    }

    function getSyndicateTokenDeployerIsActiveUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (bool syndicateDeployerIsActive) {
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].isActive;
    }

    function getSyndicateTokenLaunchTimeUsingAzimuthPoint(
        uint256 azimuthPoint
    ) external view returns (uint256 syndicateLaunchTime) {
        return _syndicate[azimuthPoint].syndicateLaunchTime;
    }

    function getSyndicateTokenExistsUsingAddress(
        address checkAddress
    ) external view returns (bool syndicateExists) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return _syndicate[azimuthPoint].syndicateContract != address(0);
    }

    function getSyndicateAzimuthPointUsingAddress(
        address checkAddress
    ) external view returns (address syndicateAddress) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        syndicateAddress = _syndicate[azimuthPoint].syndicateContract;
        return syndicateAddress;
    }

    function getSyndicateTokenOwnerAddressUsingAddress(
        address checkAddress
    ) external view returns (address syndicateOwner) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        syndicateOwner = _syndicate[azimuthPoint].syndicateOwner;
        return syndicateOwner;
    }

    function getSyndicateTokenDeployerAddressUsingAddress(
        address checkAddress
    ) external view returns (address syndicateDeployerAddress) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return _syndicate[azimuthPoint].syndicateDeployer;
    }

    function getSyndicateTokenDeployerVersionUsingAddress(
        address checkAddress
    ) external view returns (uint64 syndicateDeployerVersion) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].deployerVersion;
    }

    function getSyndicateTokenDeployerIsActiveUsingAddress(
        address checkAddress
    ) external view returns (bool syndicateDeployerIsActive) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        address deployer = _syndicate[azimuthPoint].syndicateDeployer;
        return _deployerData[deployer].isActive;
    }

    function getSyndicateTokenLaunchTimeUsingAddress(
        address checkAddress
    ) external view returns (uint256 syndicateLaunchTime) {
        uint256 azimuthPoint = _addressToAzimuthPoint[checkAddress];
        return _syndicate[azimuthPoint].syndicateLaunchTime;
    }

    // Internal Functions
    function _registerDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) internal returns (bool success) {
        require(
            syndicateDeployerData.deployerAddress != address(0),
            "Deployer is not at the null address"
        );
        require(
            !_isRegisteredDeployer[syndicateDeployerData.deployerAddress],
            "Deployer is already registered"
        );
        _syndicateDeployers.push(syndicateDeployerData.deployerAddress);
        _deployerData[
            syndicateDeployerData.deployerAddress
        ] = syndicateDeployerData;
        _isRegisteredDeployer[syndicateDeployerData.deployerAddress] = true;

        emit DeployerRegistered(
            syndicateDeployerData.deployerAddress,
            syndicateDeployerData.deployerVersion,
            syndicateDeployerData.isActive
        );

        return true;
    }

    function _deactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) internal returns (bool success) {
        address deployer = syndicateDeployerData.deployerAddress;
        SyndicateDeployerData storage deployerData = _deployerData[deployer];
        require(
            _isRegisteredDeployer[deployer],
            "Deployer is not registered and thus cannot be deactivated"
        );
        require(deployerData.isActive, "Deployer already inactive");
        deployerData.isActive = false;
        success = true;
        emit DeployerDeactivated(deployer, false);
        return success;
    }

    function _reactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) internal returns (bool success) {
        address deployer = syndicateDeployerData.deployerAddress;
        SyndicateDeployerData storage deployerData = _deployerData[deployer];
        require(
            _isRegisteredDeployer[deployer],
            "Deployer is not registered and thus cannot be deactivated"
        );
        require(!deployerData.isActive, "Deployer already active");
        deployerData.isActive = true;
        success = true;
        emit DeployerReactivated(deployer, true);
        return success;
    }

    function _registerSyndicate(
        Syndicate calldata syndicate
    ) internal returns (bool success) {
        _syndicate[syndicate.azimuthPoint] = syndicate;
        success = true;
        emit SyndicateRegistered({
            deployerAddress: msg.sender, // TODO triple check only the correct deployer can call this function
            syndicateToken: syndicate.syndicateContract,
            owner: syndicate.syndicateOwner
        });
    }

    function _updateSyndicateOwnerRegistration(
        address syndicateToken,
        address newOwner
    ) internal returns (bool success) {
        uint256 syndicatePoint = _addressToAzimuthPoint[syndicateToken];
        _syndicate[syndicatePoint].syndicateOwner = newOwner;
        success = true;
        emit SyndicateOwnerUpdated({
            deployerAddress: msg.sender,
            syndicateToken: syndicateToken,
            owner: newOwner
        });
        return success;
    }

    function _proposeNewOwner(
        address proposedOwner
    ) internal returns (bool success) {
        _pendingOwner = proposedOwner;
        success = true;
        emit OwnerProposed({
            pendingOwner: proposedOwner,
            registryOwner: msg.sender
        });
        return success;
    }

    function _acceptOwnership() internal returns (bool success) {
        address previousOwner = _owner;
        address newOwner = _pendingOwner;
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit OwnerUpdated(previousOwner, newOwner);
        return success;
    }

    function _rejectOwnership() internal returns (bool success) {
        address retainedOwner = _owner;
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit OwnershipRejected(proposedOwner, retainedOwner);
        return success;
    }

    function _nullifyProposal() internal returns (bool success) {
        address retainedOwner = _owner;
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit ProposalNullified(retainedOwner, proposedOwner);
        return success;
    }

    function _renounceOwnership() internal returns (bool success) {
        address previousOwner = _owner;
        _owner = address(0);
        success = true;
        emit OwnershipRenounced(previousOwner);
        return success;
    }
}

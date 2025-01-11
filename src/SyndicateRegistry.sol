// SPDX-License-Identifier: GPLv3

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
        require(msg.sender == _owner, Unauthorized());
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, Unauthorized());
        _;
    }

    modifier onlyValidDeployer() {
        // TODO check this logic; synidcateDeployer might need to be an array or have a better mapping?
        require(_isRegisteredDeployer[msg.sender], Unauthorized());
        _;
    }

    // Constructor

    constructor() {
        // constructor sets initial owner
        _owner = msg.sender;
    }

    // Functions
    //// receive
    receive() external payable {
        revert("Direct ETH transfers not accepted"); // TK we could make this a donation to the registry owner?
    }

    //// fallback
    fallback() external payable {
        revert("Function does not exist"); // TK we could make this a donation to the registry owner as well?
    }

    //// External Functions
    function registerDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) external onlyOwner returns (bool success) {
        return _registerDeployer(syndicateDeployerData);
        // Do we want to limit to one deployer per version? I suspect 'yes'
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
    ) external returns (bool success) {
        return _registerSyndicate(syndicate);
        // TODO this should only be callable by active deployers
        // where does the check happen to ensure there is a 1:1 mapping of @p to token?
    }

    function proposeNewOwner(
        address proposedOwner
    ) external onlyOwner returns (address pendingOwner, address owner) {
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

    // Internal Functions

    function _registerDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) internal returns (bool success) {
        require(
            syndicateDeployerData.deployerAddress != address(0),
            "Deployer is not at the null address"
        ); // make sure address is not address(0)
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
        require(
            _isRegisteredDeployer[syndicateDeployerData.deployerAddress],
            "Deployer is not registered and thus cannot be deactivated"
        );
        _deployerData[
            syndicateDeployerData.deployerAddress
        ] = syndicateDeployerData;
        return true;
    }

    function _reactivateDeployer(
        SyndicateDeployerData calldata syndicateDeployerData
    ) internal returns (bool succeess) {
        require(
            _isRegisteredDeployer[syndicateDeployerData.deployerAddress],
            "Deployer is not registered and thus cannot be reactivated"
        );
        _deployerData[
            syndicateDeployerData.deployerAddress
        ] = syndicateDeployerData;
        return true;
    }

    function _registerSyndicate(
        Syndicate calldata syndicate
    ) internal returns (bool success) {
        revert("Not yet implemented");
    }

    function _proposeNewOwner(
        address proposedOwner
    ) internal returns (address pendingOwner, address owner) {
        _pendingOwner = proposedOwner;
        // TODO emit event
        pendingOwner = proposedOwner;
        owner = _owner;
    }

    function _acceptOwnership() internal returns (bool success) {
        address previousOwner = _owner;
        address newOwner = _pendingOwner;
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        // TODO emit event with previousOwner and newOwner
        return success;
    }

    function _rejectOwnership() internal returns (bool success) {
        address retainedOwner = _owner;
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        // TODO emit event with retainedOwner and proposedOwner
        return success;
    }

    function _nullifyProposal() internal returns (bool success) {
        address retainedOwner = _owner;
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        // TODO emit event with retainedOwner and proposedOwner
        return success;
    }

    function _renounceOwnership() internal returns (bool success) {
        _owner = address(0);
        // TODO emit event renouncing ownership
        success = true;
    }
}

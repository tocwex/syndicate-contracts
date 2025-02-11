// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO natspec for internal functions
// TODO implement function for accepting ENS name

import {ReentrancyGuard} from "../lib/openzepplin-contracts/contracts/security/ReentrancyGuard.sol";
import {SyndicateRegistry} from "./SyndicateRegistry.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {ISyndicateDeployerV1} from "./interfaces/ISyndicateDeployerV1.sol";
import {IERC6551Registry} from "../lib/tokenbound/lib/erc6551/src/interfaces/IERC6551Registry.sol";
import {IERC721} from "../lib/openzepplin-contracts/contracts/token/ERC721/IERC721.sol";

contract SyndicateDeployerV1 is ISyndicateDeployerV1, ReentrancyGuard {
    // Variables
    //// Constants
    IERC6551Registry private constant TBA_REGISTRY =
        IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
    uint256 private constant MIN_FEE_TIMELOCK = 6600;

    //// Immutables
    ISyndicateRegistry private immutable i_registry;
    IERC721 private immutable i_azimuthContract;

    //// Mutables
    address private _feeRecipient;
    uint256 private _feeRate;
    uint256 private _proposedFeeRate;
    uint256 private _rateChangeBlockheight;
    bool private _betaMode = true;

    //// Mappings
    mapping(uint256 => bool) private _betaWhitelist;
    mapping(address => bool) private _deployedSyndicates;
    mapping(address => bool) private _permissionedContracts;
    mapping(address => bool) private _approvedImplementation;

    // Modifiers
    modifier onlyOwner() {
        require(
            msg.sender == i_registry.getOwner(),
            "Unauthorized: Only registry owner"
        );
        _;
    }

    modifier onlyActive() {
        bool deployerActive = _getDeployerStatus();
        require(
            deployerActive,
            "Inactive Deployer cannot launch Syndicate Token"
        );
        _;
        deployerActive = _getDeployerStatus();
        require(deployerActive, "Deployer deactivated during launch attempt");
    }

    modifier onlyUnlaunched(uint256 azimuthPoint) {
        require(
            azimuthPoint < 65535,
            "Only Stars and Galaxies can launch Syndicates from this deployer"
        );
        bool isLaunched = i_registry.getSyndicateTokenExistsUsingAzimuthPoint(
            azimuthPoint
        );
        require(!isLaunched, "This syndicate already exists");
        _;
    }

    modifier onlySyndicate(uint256 azimuthPoint) {
        require(
            _deployedSyndicates[msg.sender],
            "Unauthorized: Only syndicates launched from this deployer"
        );
        uint256 checkAzimuthPoint = i_registry
            .getSyndicateAzimuthPointUsingAddress(msg.sender);
        require(
            checkAzimuthPoint == azimuthPoint,
            "Unauthorized: Only registered syndicates"
        );
        _;
    }

    modifier onlyValidTba(
        address proposedTbaAddress,
        uint256 azimuthPoint,
        address implementation,
        bytes32 salt
    ) {
        require(
            azimuthPoint < 65535,
            "Only Stars and Galaxies can launch Syndicates from this deployer"
        );
        address derivedTba = TBA_REGISTRY.account(
            implementation,
            salt,
            block.chainid,
            address(i_azimuthContract),
            azimuthPoint
        );
        require(
            proposedTbaAddress == derivedTba,
            "Proposed token owner not a valid TBA associated with Urbit ID"
        );
        _;
    }

    modifier onlyBetaMode() {
        require(_betaMode, "Function only valid if beta mode is on");
        _;
    }

    constructor(address registryAddress, address azimuthContract, uint256 fee) {
        require(
            registryAddress != address(0),
            "Registry address cannot be zero"
        );
        require(
            azimuthContract != address(0),
            "Azimuth contract address cannot be zero"
        );
        require(registryAddress.code.length > 0, "Registry must be a contract");
        require(azimuthContract.code.length > 0, "Azimuth must be a contract");
        require(fee <= 10000, "Protocol Fee may not be greater than 100%");

        i_registry = ISyndicateRegistry(registryAddress);
        i_azimuthContract = IERC721(azimuthContract);
        _feeRecipient = msg.sender;
        _feeRate = fee;
        emit DeployerV1Deployed({
            registryAddress: registryAddress,
            fee: fee,
            feeRecipient: msg.sender
        });
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

    //// External

    // @inheritdoc ISyndicateDeployerV1
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
            require(
                _betaWhitelist[azimuthPoint],
                "Unauthorized: Urbit ID not on beta whitelist"
            );
        }
        require(
            _approvedImplementation[implementation],
            "Unauthorized: initial deployment must occur from approved tokenbound implementation"
        );
        return
            _deploySyndicate(
                msg.sender,
                initialSupply,
                maxSupply,
                azimuthPoint,
                _feeRate,
                name,
                symbol
            );
    }

    // @inheritdoc ISyndicateDeployerV1
    function registerTokenOwnerChange(
        address newOwner,
        uint256 azimuthPoint,
        address implementation,
        bytes32 salt
    )
        external
        onlySyndicate(azimuthPoint)
        onlyValidTba(newOwner, azimuthPoint, implementation, salt)
        nonReentrant
        returns (bool success)
    {
        return _registerTokenOwnerChange(msg.sender, newOwner);
    }

    function proposeFeeChange(
        uint256 proposedFee,
        uint256 targetDelay
    ) external onlyOwner returns (bool success) {
        require(
            targetDelay >= MIN_FEE_TIMELOCK,
            "Unauthorized: proposed delay must be at least 6600 blocks"
        );
        return _proposeFeeChange(proposedFee, targetDelay);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFee() external onlyOwner returns (bool success) {
        require(
            block.number >= _rateChangeBlockheight,
            "Unauthorized: rate change still timelocked"
        );
        return _changeFee();
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFeeRecipient(
        address newFeeRecipient
    ) external onlyOwner returns (bool success) {
        return _changeFeeRecipient(newFeeRecipient);
    }

    function toggleBetaMode(
        bool betaState
    ) external onlyOwner returns (bool success) {
        return _toggleBetaMode(betaState);
    }

    function addApprovedTbaImplementation(
        address contractAddress
    ) external onlyOwner returns (bool success) {
        return _addApprovedTbaImplementation(contractAddress);
    }

    function removeApprovedTbaImplementation(
        address contractAddress
    ) external onlyOwner returns (bool success) {
        return _removeApprovedTbaImplementation(contractAddress);
    }

    function addWhitelistedPoint(
        uint256 azimuthPoint
    ) external onlyOwner onlyBetaMode returns (bool success) {
        return _addWhitelistedPoint(azimuthPoint);
    }

    function batchWhitelistPoints(
        uint256[] calldata azimuthPoint
    ) external onlyOwner onlyBetaMode returns (bool success) {
        return _batchWhitelistPoints(azimuthPoint);
    }

    function removeWhitelistedPoint(
        uint256 azimuthPoint
    ) external onlyOwner onlyBetaMode returns (bool success) {
        return _removeWhitelistedPoint(azimuthPoint);
    }

    function addPermissionedContract(
        address contractAddress
    ) external onlyOwner returns (bool success) {
        return _addPermissionedContract(contractAddress);
    }

    function removePermissionedContract(
        address contractAddress
    ) external onlyOwner returns (bool success) {
        return _removePermissionedContract(contractAddress);
    }

    function dissolveSyndicateInRegistry(
        uint256 azimuthPoint
    ) external onlySyndicate(azimuthPoint) nonReentrant returns (bool success) {
        return _dissolveSyndicateInRegistry(azimuthPoint);
    }

    function executeCall(
        address target,
        bytes calldata data
    )
        external
        onlyOwner
        nonReentrant
        returns (bool success, bytes memory result)
    {
        return _executeCall(target, data);
    }

    // @inheritdoc ISyndicateDeployerV1
    function getRegistry() external view returns (address syndicateRegistry) {
        return address(i_registry);
    }

    // @inheritdoc ISyndicateDeployerV1
    function getOwner() external view returns (address deployerOwner) {
        return i_registry.getOwner();
    }

    // @inheritdoc ISyndicateDeployerV1
    function getPendingOwner() external view returns (address pendingOwner) {
        return i_registry.getPendingOwner();
    }

    // @inheritdoc ISyndicateDeployerV1
    function getFeeRecipient() external view returns (address feeRecipient) {
        return _feeRecipient;
    }

    // @inheritdoc ISyndicateDeployerV1
    function getFee() external view returns (uint256 fee) {
        return _feeRate;
    }

    function getDeployerStatus() external view returns (bool isActive) {
        return _getDeployerStatus();
    }

    function getRateChangeBlockheight()
        external
        view
        returns (uint256 rateChangeBlockheight)
    {
        return _rateChangeBlockheight;
    }

    // TODO add natspec
    function isPermissionedContract(
        address contractAddress
    ) external view returns (bool isPermissioned) {
        return _permissionedContracts[contractAddress];
    }

    function isRelatedSyndicate(
        address contractAddress
    ) external view returns (bool isRelated) {
        return _deployedSyndicates[contractAddress];
    }

    function inBetaMode() external view returns (bool betaState) {
        return _betaMode;
    }

    function isApprovedImplementation(
        address checkAddress
    ) external view returns (bool approvedImplementation) {
        return _approvedImplementation[checkAddress];
    }

    //// Internal Functions
    // TODO add natspec
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
            address(this),
            tokenOwner,
            initialSupply,
            maxSupply,
            azimuthPoint,
            protocolFee,
            name,
            symbol
        );

        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry
            .Syndicate({
                syndicateOwner: tokenOwner,
                syndicateContract: address(syndicateTokenV1),
                syndicateDeployer: address(this),
                syndicateLaunchTime: block.number,
                azimuthPoint: azimuthPoint
            });

        i_registry.registerSyndicate(syndicate);
        _deployedSyndicates[address(syndicateTokenV1)] = true;
        emit TokenDeployed({
            token: address(syndicateTokenV1),
            owner: tokenOwner,
            azimuthPoint: azimuthPoint
        });
        return address(syndicateTokenV1);
    }

    // TODO add natspec
    function _registerTokenOwnerChange(
        address syndicateToken,
        address newOwner
    ) internal returns (bool success) {
        success = i_registry.updateSyndicateOwnerRegistration(
            syndicateToken,
            newOwner
        );
        emit TokenOwnerChanged({token: syndicateToken, newOwner: newOwner});
        return success;
    }

    function _proposeFeeChange(
        uint256 proposedFee,
        uint256 targetDelay
    ) internal returns (bool success) {
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

    function _changeFee() internal returns (bool success) {
        _feeRate = _proposedFeeRate;
        _rateChangeBlockheight = 0;
        _proposedFeeRate = 0;
        success = true;

        emit FeeUpdated({newFee: _feeRate, updateBlockheight: block.number});

        return success;
    }

    // TODO add natspec
    function _changeFeeRecipient(
        address newFeeRecipient
    ) internal returns (bool success) {
        _feeRecipient = newFeeRecipient;
        success = true;
        emit FeeRecipientUpdated({feeRecipient: newFeeRecipient});
        return success;
    }

    // TODO add natspec
    function _toggleBetaMode(bool betaState) internal returns (bool success) {
        _betaMode = betaState;
        success = true;
        emit BetaModeChanged({betaMode: betaState});

        return success;
    }

    function _addApprovedTbaImplementation(
        address contractAddress
    ) internal returns (bool success) {
        _approvedImplementation[contractAddress] = true;
        success = true;

        emit AddedTbaImplementation({
            tbaImplementationAddress: contractAddress,
            deployerOwner: msg.sender
        });

        return success;
    }

    function _removeApprovedTbaImplementation(
        address contractAddress
    ) internal returns (bool success) {
        _approvedImplementation[contractAddress] = true;
        success = true;

        emit RemovedTbaImplementation({
            tbaImplementationAddress: contractAddress,
            deployerOwner: msg.sender
        });

        return success;
    }

    // TODO add natspec

    function _addWhitelistedPoint(
        uint256 azimuthPoint
    ) internal returns (bool success) {
        _betaWhitelist[azimuthPoint] = true;
        success = true;

        emit AzimuthPointAddedToWhitelist({azimuthPoint: azimuthPoint});

        return success;
    }

    // TODO add natspec
    function _batchWhitelistPoints(
        uint256[] calldata azimuthPoint
    ) internal returns (bool success) {
        require(azimuthPoint.length > 0, "Empty array");
        for (uint256 i = 0; i < azimuthPoint.length; i++) {
            _betaWhitelist[azimuthPoint[i]] = true;
            emit AzimuthPointAddedToWhitelist({azimuthPoint: azimuthPoint[i]});
        }
        success = true;

        return success;
    }

    // TODO add natspec
    function _removeWhitelistedPoint(
        uint256 azimuthPoint
    ) internal returns (bool success) {
        _betaWhitelist[azimuthPoint] = false;
        success = true;

        emit AzimuthPointRemovedFromWhitelist({azimuthPoint: azimuthPoint});

        return success;
    }

    // TODO add natspec
    function _addPermissionedContract(
        address contractAddress
    ) internal returns (bool success) {
        _permissionedContracts[contractAddress] = true;
        success = true;
        emit PermissionedContractAdded({permissionedContract: contractAddress});
        return success;
    }

    // TODO add natspec
    function _removePermissionedContract(
        address contractAddress
    ) internal returns (bool success) {
        _permissionedContracts[contractAddress] = false;
        success = true;
        emit PermissionedContractRemoved({
            permissionedContract: contractAddress
        });
        return success;
    }

    function _dissolveSyndicateInRegistry(
        uint256 azimuthPoint
    ) internal returns (bool success) {
        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry
            .Syndicate({
                syndicateOwner: address(0),
                syndicateContract: address(0),
                syndicateDeployer: address(0),
                syndicateLaunchTime: uint256(0),
                azimuthPoint: azimuthPoint
            });

        i_registry.dissolveSyndicate(syndicate);
        _deployedSyndicates[msg.sender] = false;
        success = true;
        // TODO Add Event
        return success;
    }

    function _executeCall(
        address target,
        bytes calldata data
    ) internal returns (bool success, bytes memory result) {
        // Add basic checks
        require(target != address(0), "Invalid target");
        require(target != address(this), "Cannot call self");

        // Log attempt
        emit ExternalCallAttempted(target, data);

        // Make call
        (success, result) = target.call(data);
        require(success, "Call failed");

        // Log result
        emit ExternalCallExecuted(target, data, success);

        return (success, result);
    }

    function _getDeployerStatus() internal view returns (bool isActive) {
        ISyndicateRegistry.SyndicateDeployerData
            memory syndicateDeployerData = i_registry.getDeployerData(
                address(this)
            );
        return syndicateDeployerData.isActive;
    }
}

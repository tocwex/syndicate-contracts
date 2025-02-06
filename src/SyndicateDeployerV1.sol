// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO natspec for internal functions
// TODO implement reentrancy guards
// TODO implement function for accepting ENS name
// TODO block max fee from being >100%
import {SyndicateRegistry} from "./SyndicateRegistry.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {ISyndicateDeployerV1} from "./interfaces/ISyndicateDeployerV1.sol";
import {IERC6551Registry} from "../lib/tokenbound/lib/erc6551/src/interfaces/IERC6551Registry.sol";
import {IERC721} from "../lib/openzepplin-contracts/contracts/token/ERC721/IERC721.sol";

contract SyndicateDeployerV1 is ISyndicateDeployerV1 {
    // Variables
    //// Constants
    IERC6551Registry private constant TBA_REGISTRY =
        IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

    //// Immutables
    ISyndicateRegistry private immutable i_registry;
    IERC721 private immutable i_azimuthContract;

    //// Mutables
    address private _feeRecipient;
    uint256 private _fee;
    bool private _betaMode = true;

    // Arrays

    // Mappings
    mapping(uint256 => bool) private _betaWhitelist;
    mapping(address => bool) private _deployedSyndicates;
    mapping(address => bool) private _permissionedContracts;

    // Modifiers

    modifier onlyOwner() {
        require(
            msg.sender == i_registry.getOwner(),
            "Unauthorized: Only registry owner"
        );
        _;
    }

    modifier onlyActive() {
        ISyndicateRegistry.SyndicateDeployerData
            memory syndicateDeployerData = i_registry.getDeployerData(
                address(this)
            );
        require(
            syndicateDeployerData.isActive,
            "Inactive Deployer cannot launch Syndicate Token"
        );
        _;
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

    modifier onlySyndicate() {
        require(
            _deployedSyndicates[msg.sender],
            "Unauthorized: Only syndicates launched from this deployer"
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

    constructor(address registryAddress, address azimuthContract, uint256 fee) {
        i_registry = ISyndicateRegistry(registryAddress);
        i_azimuthContract = IERC721(azimuthContract);
        _feeRecipient = msg.sender;
        _fee = fee;
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
        returns (address syndicateToken)
    {
        if (_betaMode) {
            require(
                _betaWhitelist[azimuthPoint],
                "Unauthorized: Urbit ID not on beta whitelist"
            );
        }
        return
            _deploySyndicate(
                msg.sender,
                initialSupply,
                maxSupply,
                azimuthPoint,
                _fee,
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
        onlySyndicate
        onlyValidTba(newOwner, azimuthPoint, implementation, salt)
        returns (bool success)
    {
        return _registerTokenOwnerChange(msg.sender, newOwner);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFee(uint256 fee) external onlyOwner {
        require(fee <= 10000, "Fee must not exceed 100%");
        return _changeFee(fee);
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

    function addWhitelistedPoint(
        uint256 azimuthPoint
    ) external onlyOwner returns (bool success) {
        return _addWhitelistedPoint(azimuthPoint);
    }

    function batchWhitelistPoints(
        uint256[] calldata azimuthPoint
    ) external onlyOwner returns (bool success) {
        return _batchWhitelistPoints(azimuthPoint);
    }

    function removeWhitelistedPoint(
        uint256 azimuthPoint
    ) external onlyOwner returns (bool success) {
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
    ) external onlySyndicate returns (bool success) {
        return _dissolveSyndicateInRegistry(azimuthPoint);
    }

    // TODO make nonReentrant
    function executeCall(
        address target,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory result) {
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
        return _fee;
    }

    // TODO add natspec
    function checkIfPermissioned(
        address contractAddress
    ) external view returns (bool isPermissioned) {
        return _permissionedContracts[contractAddress];
    }

    function inBetaMode() external view returns (bool betaState) {
        return _betaMode;
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

        _deployedSyndicates[address(syndicateTokenV1)] = true;
        i_registry.registerSyndicate(syndicate);
        emit TokenDeployed({
            token: address(syndicateTokenV1),
            owner: tokenOwner
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

    // TODO add natspec
    function _changeFee(uint256 fee) internal {
        _fee = fee;
        emit FeeUpdated(fee);
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

    // TODO add events for permissioned contracts

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

        _deployedSyndicates[msg.sender] = false;

        i_registry.dissolveSyndicate(syndicate);
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
}

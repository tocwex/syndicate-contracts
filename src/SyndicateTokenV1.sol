// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO confirm best way to implement i_maxSupply; is it as a null value check, using openZepplin's ERC20Cap contract, etc.
// TODO implment reentrancy guards
// TODO implement function for accepting ENS name
// TODO add natspec for internal functions

// TODO add a post-launch 'setMaxSupply' fuction???
// TODO flag and function to prevent minting directly by the owner, such that they cannot 'rug' permissioned contracts by way of extraneous mints outside the system and then dump tokens on the market?

import {ERC20} from "@openzepplin/token/ERC20/ERC20.sol";
import {ISyndicateDeployerV1} from "../src/interfaces/ISyndicateDeployerV1.sol";
import {ISyndicateTokenV1} from "../src/interfaces/ISyndicateTokenV1.sol";

contract SyndicateTokenV1 is ERC20, ISyndicateTokenV1 {
    // ERC20 Parent Contract Variables
    // mapping(address => uint256) private _balances;
    // mapping(address => mapping(address => uint256)) private _allowances;
    // uint256 private _totalSupply;
    // string private _name;
    // string private _symbol;
    // State Variables
    //// Constants
    uint256 private constant BASIS_POINTS = 10000;

    //// Immutables
    ISyndicateDeployerV1 public immutable i_syndicateDeployer;
    uint256 private immutable i_maxSupply;
    uint256 private immutable i_azimuthPoint;
    uint256 private immutable i_protocolFeeMax;

    //// Regular State Variables
    uint256 private _protocolFeeCurrent;
    address private _owner;
    bool private _isCannonical = true;
    bool private _customWhitelist = true; // TK This will mean anyone launching a v1 contract will need to execute a transaction in order to allow any future permissioned contracts to interact with their Syndicate Token

    // Mappings
    mapping(address => bool) private _whitelistedContracts;

    // Events
    // Errors
    // error Unauthorized();

    // Constructor
    constructor(
        address deployerAddress,
        address owner,
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 azimuthPoint,
        uint256 protocolFee,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        i_syndicateDeployer = ISyndicateDeployerV1(deployerAddress);
        require(msg.sender == deployerAddress, "Syndicate Tokens must be deployed from the Syndicate factory contract");
        _owner = owner;
        i_maxSupply = maxSupply;
        i_azimuthPoint = azimuthPoint;
        i_protocolFeeMax = protocolFee;
        _protocolFeeCurrent = protocolFee;
        _mint(owner, initialSupply); // totalSupply is managed by _mint and _burn fuctions
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized: Only syndicate owner");
        _;
    }

    modifier onlyPermissionedContract() {
        require(
            i_syndicateDeployer.checkIfPermissioned(msg.sender), "Unauthorized: Not a permissioned contract address"
        );
        if (_customWhitelist) {
            require(_whitelistedContracts[msg.sender], "Unauthorized: Not in Syndicate custom whitelist");
        }
        _;
    }

    modifier onlySyndicateEcosystemOwner() {
        require(
            i_syndicateDeployer.getOwner() == msg.sender,
            "Unauthorized: Only the SyndicateDeployer owner may call this function"
        );
        _;
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

    //// external
    function mint(address account, uint256 amount) external onlyOwner {
        return _mint(account, amount);
    }

    function permissionedMint(address account, uint256 amount) external onlyPermissionedContract {
        return _permissionedMint(account, amount);
    }

    function batchMint(address[] calldata account, uint256[] calldata amount) external onlyOwner {
        return _batchMint(account, amount);
    }

    function permissionedBatchMint(address[] calldata account, uint256[] calldata amount)
        external
        onlyPermissionedContract
    {
        return _permissionedBatchMint(account, amount);
    }

    function updateOwnershipTba(address newOwner, address tbaImplementation, bytes32 salt)
        external
        onlyOwner
        returns (bool success)
    {
        return _updateOwnershipTba(newOwner, tbaImplementation, salt);
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        return _renounceOwnership();
    }

    function dissolveSyndicate() external onlyOwner returns (bool success) {
        return _dissolveSyndicate();
    }

    function addWhitelistedContract(address contractAddress) external onlyOwner returns (bool success) {
        return _addWhitelistedContract(contractAddress);
    }

    function removeWhitelistedContract(address contractAddress) external onlyOwner returns (bool success) {
        return _removeWhitelistedContract(contractAddress);
    }

    function reduceFee(uint256 newFee) external onlySyndicateEcosystemOwner returns (bool success) {
        return _reduceFee(newFee);
    }

    function getDeployerAddress() external view returns (address) {
        return address(i_syndicateDeployer);
    }

    function getMaxSupply() external view returns (uint256) {
        return i_maxSupply;
    }

    function getAzimuthPoint() external view returns (uint256) {
        return i_azimuthPoint;
    }

    function getMaxProtocolFee() external view returns (uint256) {
        return i_protocolFeeMax;
    }

    function getProtocolFee() external view returns (uint256) {
        return _protocolFeeCurrent;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function getSyndicateStatus() external view returns (bool isCannonical) {
        isCannonical = _isCannonical;
    }

    function usesCustomWhitelist() external view returns (bool usesCustom) {
        usesCustom = _customWhitelist;
    }

    function isWhitelistedContract(address contractAddress) external view returns (bool isWhitelisted) {
        isWhitelisted = _whitelistedContracts[contractAddress];
    }

    function getFeeRecipient() external view returns (address feeRecipient) {
        feeRecipient = i_syndicateDeployer.getFeeRecipient();
    }

    //// internal
    function _mint(address account, uint256 amount) internal override {
        require(totalSupply() + amount <= i_maxSupply, "ERC20: Mint over maxSupply limit");
        uint256 fee_ = (amount * _protocolFeeCurrent) / BASIS_POINTS; // TODO check decimals on different fee storage variables
        // TODO figure out how solidity handles rounding errors
        uint256 amount_ = amount - fee_;

        address feeRecipient = i_syndicateDeployer.getFeeRecipient();

        super._mint(account, amount_);
        super._mint(feeRecipient, fee_);
    }

    function _permissionedMint(address account, uint256 amount) internal {
        require(totalSupply() + amount <= i_maxSupply, "ERC20: Mint over masSupply limit");
        super._mint(account, amount);
    }

    function _batchMint(address[] calldata account, uint256[] calldata amount) internal {
        require(account.length == amount.length, "Array length mismatch");
        require(account.length > 0, "Empty arrays");

        uint256 totalAmount;
        uint256 totalFee;

        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
            uint256 fee = (amount[i] * _protocolFeeCurrent) / 10000; // TODO check the decimals on fee calculations
            totalFee += fee;
            _permissionedMint(account[i], amount[i] - fee);
        }

        require(totalSupply() + totalAmount <= i_maxSupply, "ERC20: Batch mint over maxSuply limit");

        if (totalFee > 0) {
            address feeRecipient = i_syndicateDeployer.getFeeRecipient();
            _permissionedMint(feeRecipient, totalFee);
        }
    }

    function _permissionedBatchMint(address[] calldata account, uint256[] calldata amount) internal {
        require(account.length == amount.length, "Array length mismatch");
        require(account.length > 0, "Empty arrays");

        uint256 totalAmount;

        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
            _permissionedMint(account[i], amount[i]);
        }

        require(totalSupply() + totalAmount <= i_maxSupply, "ERC20: Batch mint over maxSupply limit");
    }

    function _updateOwnershipTba(address newOwner, address implementation, bytes32 salt)
        internal
        returns (bool success)
    {
        _owner = newOwner;
        success = true;

        bool registeryUpdated =
            i_syndicateDeployer.registerTokenOwnerChange(newOwner, i_azimuthPoint, implementation, salt);
        require(registeryUpdated, "Registry must have updated to proceed");

        emit OwnershipTbaUpdated(newOwner);

        return success;
    }

    function _renounceOwnership() internal returns (bool success) {
        _owner = address(0);
        success = true;
        emit OwnershipRenounced(msg.sender);
        return success;
    }

    function _dissolveSyndicate() internal returns (bool success) {
        require(_isCannonical, "Syndicate Token is already dissolved");
        _isCannonical = false;

        success = i_syndicateDeployer.dissolveSyndicateInRegistry(i_azimuthPoint);

        require(success, "Dissolution of syndicate failed");
        emit SyndicateDissolved(block.number);
        return success;
    }

    function _addWhitelistedContract(address contractAddress) internal returns (bool success) {
        _whitelistedContracts[contractAddress] = true;
        success = true;
        emit ContractAddedToWhitelist({contractAddress: contractAddress});
        return success;
    }

    function _removeWhitelistedContract(address contractAddress) internal returns (bool success) {
        _whitelistedContracts[contractAddress] = false;
        success = true;
        emit contractRemovedFromWhitelist({contractAddress: contractAddress});
        return success;
    }

    function _reduceFee(uint256 newFee) internal returns (bool success) {
        require(newFee < i_protocolFeeMax, "Unauthorized: New fee must be lower than max protocol fee");
        require(newFee < _protocolFeeCurrent, "Unauthorized: New fee must be lower than current fee");
        _protocolFeeCurrent = newFee;
        success = true;

        emit ProtocolFeeUpdated({newFee: newFee});

        return success;
    }
}

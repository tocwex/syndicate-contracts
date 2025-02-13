// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO add natspec for internal functions

import {ReentrancyGuard} from "../lib/openzepplin-contracts/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzepplin/token/ERC20/ERC20.sol";
import {ISyndicateDeployerV1} from "../src/interfaces/ISyndicateDeployerV1.sol";
import {ISyndicateTokenV1} from "../src/interfaces/ISyndicateTokenV1.sol";

contract SyndicateTokenV1 is ERC20, ISyndicateTokenV1, ReentrancyGuard {
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
    uint256 private immutable i_azimuthPoint;
    uint256 private immutable i_protocolFeeMax;

    //// Regular State Variables
    uint256 private _maxSupply;
    uint256 private _protocolFeeCurrent;
    address private _owner;
    bool private _setCap;
    bool private _isCannonical = true;
    bool private _defaultWhitelist = false;
    bool private _ownerMintable = true;

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
        require(
            msg.sender == deployerAddress,
            "Syndicate Tokens must be deployed from the Syndicate factory contract"
        );
        require(
            protocolFee <= 10000,
            "Protocol Fee cannot be greater than 100%"
        );
        require(
            isValidName(name),
            "Invalid name: Must be <50 approved characters"
        );
        require(
            isValidSymbol(symbol),
            "Invalid symbol: Must be <16 approved characters"
        );

        i_syndicateDeployer = ISyndicateDeployerV1(deployerAddress);
        _owner = owner;
        if (maxSupply == type(uint256).max) {
            _maxSupply = maxSupply;
            _setCap = false;
        } else {
            _maxSupply = maxSupply;
            _setCap = true;
            emit TokenMaxSupplySet({maxSupply: maxSupply});
        }
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
            i_syndicateDeployer.isPermissionedContract(msg.sender),
            "Unauthorized: Not a permissioned contract address"
        );
        if (!_defaultWhitelist) {
            require(
                _whitelistedContracts[msg.sender],
                "Unauthorized: Not in Syndicate custom whitelist"
            );
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

    modifier onlyOwnerMintable() {
        require(
            _ownerMintable,
            "Unauthorized: Owner does not have minting rights"
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
    function mint(
        address account,
        uint256 amount
    ) external onlyOwner onlyOwnerMintable nonReentrant {
        return _mint(account, amount);
    }

    function permissionedMint(
        address account,
        uint256 amount
    ) external onlyPermissionedContract nonReentrant {
        return _permissionedMint(account, amount);
    }

    function batchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) external onlyOwner onlyOwnerMintable nonReentrant {
        return _batchMint(account, amount);
    }

    function permissionedBatchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) external onlyPermissionedContract nonReentrant {
        return _permissionedBatchMint(account, amount);
    }

    function updateOwnershipTba(
        address newOwner,
        address tbaImplementation,
        bytes32 salt
    ) external onlyOwner nonReentrant returns (bool success) {
        return _updateOwnershipTba(newOwner, tbaImplementation, salt);
    }

    function renounceMintingRights() external onlyOwner returns (bool sucess) {
        return _renounceMintingRights();
    }

    function renounceOwnership() external onlyOwner returns (bool success) {
        return _renounceOwnership();
    }

    function dissolveSyndicate()
        external
        onlyOwner
        nonReentrant
        returns (bool success)
    {
        return _dissolveSyndicate();
    }

    function addWhitelistedContract(
        address contractAddress
    ) external onlyOwner returns (bool success) {
        return _addWhitelistedContract(contractAddress);
    }

    function removeWhitelistedContract(
        address contractAddress
    ) external onlyOwner returns (bool success) {
        return _removeWhitelistedContract(contractAddress);
    }

    function toggleDefaultWhitelist(
        bool state
    ) external onlyOwner returns (bool success) {
        return _toggleDefaultWhitelist(state);
    }

    function reduceFee(
        uint256 newFee
    ) external onlySyndicateEcosystemOwner returns (bool success) {
        return _reduceFee(newFee);
    }

    function setMaxSupply(
        uint256 setCap
    ) external onlyOwner returns (bool success) {
        require(!_setCap, "Token max supply already set");
        require(
            setCap >= totalSupply(),
            "Max supply must be greater than or equal to current total supply"
        );
        return _setMaxSupply(setCap);
    }

    function getDeployerAddress() external view returns (address) {
        return address(i_syndicateDeployer);
    }

    function getMaxSupply() external view returns (uint256) {
        return _maxSupply;
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

    function isSupplyCapped() external view returns (bool isCapped) {
        return _setCap;
    }

    function isOwnerMintable() external view returns (bool ownerMintable) {
        return _ownerMintable;
    }

    function getSyndicateStatus() external view returns (bool isCannonical) {
        isCannonical = _isCannonical;
    }

    function usesDefaultWhitelist() external view returns (bool usesDefault) {
        usesDefault = _defaultWhitelist;
    }

    function isWhitelistedContract(
        address contractAddress
    ) external view returns (bool isWhitelisted) {
        isWhitelisted = _whitelistedContracts[contractAddress];
    }

    function getFeeRecipient() external view returns (address feeRecipient) {
        feeRecipient = i_syndicateDeployer.getFeeRecipient();
    }

    //// internal
    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply() + amount <= _maxSupply,
            "ERC20: Mint over maxSupply limit"
        );
        uint256 fee_ = (amount * _protocolFeeCurrent) / BASIS_POINTS;
        uint256 amount_ = amount - fee_;

        address feeRecipient = i_syndicateDeployer.getFeeRecipient();

        super._mint(account, amount_);
        super._mint(feeRecipient, fee_);
        emit MintFeeIncurred({feeRecipient: feeRecipient, fee: fee_});
    }

    function _permissionedMint(address account, uint256 amount) internal {
        require(
            totalSupply() + amount <= _maxSupply,
            "ERC20: Mint over maxSupply limit"
        );
        super._mint(account, amount);
    }

    function _batchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) internal {
        require(account.length == amount.length, "Array length mismatch");
        require(account.length > 0, "Empty arrays");

        uint256 totalAmount;
        uint256 totalFee;

        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
            uint256 fee = (amount[i] * _protocolFeeCurrent) / BASIS_POINTS;
            totalFee += fee;
            _permissionedMint(account[i], amount[i] - fee);
        }

        require(
            totalSupply() + totalAmount <= _maxSupply,
            "ERC20: Batch mint over maxSuply limit"
        );

        if (totalFee > 0) {
            address feeRecipient = i_syndicateDeployer.getFeeRecipient();
            _permissionedMint(feeRecipient, totalFee);
            emit BatchMintFeeIncurred({
                feeRecipient: feeRecipient,
                totalFees: totalFee
            });
        } else if (_protocolFeeCurrent > 0) {
            require(totalFee > 0, "Invalid Fee Calculation");
        }
    }

    function _permissionedBatchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) internal {
        require(account.length == amount.length, "Array length mismatch");
        require(account.length > 0, "Empty arrays");

        uint256 totalAmount;

        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
            _permissionedMint(account[i], amount[i]);
        }

        require(
            totalSupply() + totalAmount <= _maxSupply,
            "ERC20: Batch mint over maxSupply limit"
        );
    }

    function _updateOwnershipTba(
        address newOwner,
        address implementation,
        bytes32 salt
    ) internal returns (bool success) {
        address oldOwner = _owner;
        _owner = newOwner;
        success = true;

        bool registeryUpdated = i_syndicateDeployer.registerTokenOwnerChange(
            newOwner,
            i_azimuthPoint,
            implementation,
            salt
        );
        require(registeryUpdated, "Registry must have updated to proceed");

        emit OwnershipTbaUpdated({
            newOwner: newOwner,
            previousOwner: oldOwner,
            tbaImplementation: implementation,
            tbaSalt: salt,
            blockheight: block.number
        });

        return success;
    }

    function _renounceMintingRights() internal returns (bool success) {
        _ownerMintable = false;
        success = true;
        emit MintingRightsRenounced({tokenOwner: msg.sender});
        return success;
    }

    function _renounceOwnership() internal returns (bool success) {
        _owner = address(0);
        if (_ownerMintable) {
            _ownerMintable = false;
            emit MintingRightsRenounced({tokenOwner: msg.sender});
        }
        if (!_setCap) {
            _setCap = true;
            emit TokenMaxSupplySet({maxSupply: _maxSupply});
        }
        success = true;
        emit OwnershipRenounced({
            lastOwner: msg.sender,
            blockheight: block.number
        });
        return success;
    }

    function _dissolveSyndicate() internal returns (bool success) {
        require(_isCannonical, "Syndicate Token is already dissolved");
        _isCannonical = false;

        success = i_syndicateDeployer.dissolveSyndicateInRegistry(
            i_azimuthPoint
        );

        require(success, "Dissolution of syndicate failed");
        emit SyndicateDissolved({blockheight: block.number});
        return success;
    }

    function _addWhitelistedContract(
        address contractAddress
    ) internal returns (bool success) {
        _whitelistedContracts[contractAddress] = true;
        success = true;
        emit ContractAddedToWhitelist({contractAddress: contractAddress});
        return success;
    }

    function _removeWhitelistedContract(
        address contractAddress
    ) internal returns (bool success) {
        _whitelistedContracts[contractAddress] = false;
        success = true;
        emit ContractRemovedFromWhitelist({contractAddress: contractAddress});
        return success;
    }

    function _toggleDefaultWhitelist(
        bool state
    ) internal returns (bool success) {
        _defaultWhitelist = state;
        success = true;
        emit ToggleDefaultWhitelist({
            tokenOwner: msg.sender,
            defaultsWhitelisted: state
        });
        return success;
    }

    function _reduceFee(uint256 newFee) internal returns (bool success) {
        require(
            newFee < i_protocolFeeMax,
            "Unauthorized: New fee must be lower than max protocol fee"
        );
        require(
            newFee < _protocolFeeCurrent,
            "Unauthorized: New fee must be lower than current fee"
        );
        _protocolFeeCurrent = newFee;
        success = true;

        emit ProtocolFeeUpdated({newFee: newFee});

        return success;
    }

    function _setMaxSupply(uint256 setCap) internal returns (bool success) {
        _maxSupply = setCap;
        _setCap = true;
        success = true;
        emit TokenMaxSupplySet({maxSupply: setCap});
        return success;
    }

    function isValidName(string memory name) internal pure returns (bool) {
        bytes memory b = bytes(name);
        // Allow up to 50 characters, while requiring at least 1
        if (b.length == 0 || b.length > 50) return false;
        for (uint256 i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            bool isDigit = (char >= 0x30 && char <= 0x39); // 0-9
            bool isUppercase = (char >= 0x41 && char <= 0x5A); // Uppercase letters
            bool isLowercase = (char >= 0x61 && char <= 0x7A); // Lowercase letters
            bool isSpecial = (char == 0x20 || char == 0x2D || char == 0x7E); // '-' or ' ' or '~'
            if (!(isDigit || isUppercase || isLowercase || isSpecial)) {
                return false;
            }
        }
        return true;
    }

    function isValidSymbol(string memory symbol) internal pure returns (bool) {
        bytes memory b = bytes(symbol);
        // Allow up to 16 characters to accommodate potential full planet names with space
        if (b.length == 0 || b.length > 16) return false;
        for (uint256 i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            bool isUppercase = (char >= 0x41 && char <= 0x5A); // Uppercase letters only
            bool isDigit = (char >= 0x30 && char <= 0x39); // 0-9
            bool isSpecial = (char == 0x2D || char == 0x7E); // '-' or '~'
            if (!(isUppercase || isDigit || isSpecial)) {
                return false;
            }
        }
        return true;
    }
}

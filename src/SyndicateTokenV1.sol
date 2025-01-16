// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO update openzepplin contracts to ^5.0.0 ?
// TODO
// For the initial version of the token launch feature in %slab, we will use a basic ERC20 factory contract that enables a visitor to pass in constructor values to set:
//
// Total supply
// Initial supply
// Initial mint amount and target address
// Ownership address
// Token name
// Token symbol
//
// TODO change state variables to private and implement getter functions

import {ERC20} from "@openzepplin/token/ERC20/ERC20.sol";
import {ISyndicateDeployerV1} from "../src/interfaces/ISyndicateDeployerV1.sol";

contract SyndicateTokenV1 is ERC20 {
    // ERC20 Parent Contract Variables
    // mapping(address => uint256) private _balances;
    // mapping(address => mapping(address => uint256)) private _allowances;
    // uint256 private _totalSupply;
    // string private _name;
    // string private _symbol;
    // State Variables
    //// Constants

    //// Immutables
    ISyndicateDeployerV1 public immutable i_syndicateDeployer; // Make static deployer address?
    uint256 private immutable i_maxSupply;
    uint256 private immutable i_azimuthPoint;
    //// Regular State Variables
    address private _owner;

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
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        i_syndicateDeployer = ISyndicateDeployerV1(deployerAddress);
        require(
            msg.sender == deployerAddress,
            "Syndicate Tokens must be deployed from the Syndicate factory contract"
        );
        _owner = owner;
        i_maxSupply = maxSupply;
        i_azimuthPoint = azimuthPoint;
        _mint(owner, initialSupply); // totalSupply is managed by _mint and _burn fuctions
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized");
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

    function updateOwnershipTba(
        address newOwner,
        address tbaImplementation
    ) external onlyOwner returns (bool success) {
        return _updateOwnershipTba(newOwner, tbaImplementation);
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

    function getOwner() external view returns (address) {
        return _owner;
    }

    //// public

    //// internal
    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply() + amount <= i_maxSupply,
            "ERC20: Mint over maxSupply limit"
        );
        super._mint(account, amount);
    }

    function _updateOwnershipTba(
        address newOwner,
        address tbaImplementation
    ) internal returns (bool success) {
        // Checks
        bool isValid = i_syndicateDeployer.validateTokenOwnerChange(
            newOwner,
            i_azimuthPoint,
            tbaImplementation
        );
        require(
            isValid,
            "New Owner must be a valid TBA associated with Urbit ID"
        );

        // internal changes
        _owner = newOwner;
        success = true;

        // external calls
        bool registeryUpdated = i_syndicateDeployer.registerTokenOwnerChange(
            address(this),
            newOwner
        );
        require(registeryUpdated, "Registry must have updated to proceed");
        return success;
    }
    //// private
    //// view / pure
}

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
    address public immutable SYNDICATE_DEPLOYER; // Make static deployer address?
    uint256 public immutable maxSupply;
    uint256 public immutable azimuthPoint;
    //// Regular State Variables
    address public owner;

    // Events
    // Errors
    // error Unauthorized();

    // Constructor
    constructor(
        address _owner,
        uint256 _initialSupply,
        uint256 _maxSupply,
        uint256 _azimuthPoint,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(
            msg.sender == SYNDICATE_DEPLOYER,
            "Syndicate Tokens must be deployed from the Syndicate factory contract"
        );
        owner = _owner;
        maxSupply = _maxSupply;
        azimuthPoint = _azimuthPoint;
        _mint(msg.sender, _initialSupply); // totalSupply is managed by _mint and _burn fuctions
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
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

    function updateOwner(
        address newOwner,
        address tbaImplementation
    ) external onlyOwner returns (bool success) {
        return _updateOwner(newOwner, tbaImplementation);
    }

    //// public

    //// internal
    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply() + amount <= maxSupply,
            "ERC20: Mint over maxSupply limit"
        );
        super._mint(account, amount);
    }

    function _updateOwner(
        address newOwner,
        address tbaImplementation
    ) internal returns (bool success) {
        success = false;
        owner = newOwner;
        // TODO figure out how to check that the new owner is a valid owner.
        // PSEUDOCODE
        // proposedTokenOwner = newOwner;
        // proposedTbaImplementation = tbaImplementation;
        // calculatedOwner = syndicateDeployerV1.validateTokenOwnerChange(
        //      proposedTokenOwner,
        //      azimuthPoint,
        //      tbaImplementation
        // );
        // require(newOwner == calculatedOwner, "new owner must be TBA controlled by your Urbit ID");
        // success = true;
        // This logic could occur a few ways; I could include a warning flag in the registry that the owner is not the original owner. Or I could rely on an eligibility check in the deployer contract. I think probably the right way to do this is to look at the deployer contract and validate there? does that mean I need to import the deployer interface here to the ERC20 contract?
        return success;
    }
    //// private
    //// view / pure
}

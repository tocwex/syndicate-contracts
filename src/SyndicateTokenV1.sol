// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO update openzepplin contracts to ^5.0.0 ?
// TODO implement receive and fallback Functions
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
    address public immutable i_owner; // TK is owner really immutable? TBA addresses *may* change, do we want there to be some possible ownership update logic?

    //// Regular State Variables
    uint256 public maxSupply;

    // Events
    // Errors

    // Constructor
    constructor(
        address _owner,
        uint256 _initialSupply,
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(
            msg.sender == SYNDICATE_DEPLOYER,
            "Syndicate Tokens must be deployed from the Syndicate factory contract"
        );
        i_owner = _owner;
        maxSupply = _maxSupply;
        _mint(msg.sender, _initialSupply); // totalSupply is managed by _mint and _burn fuctions
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

    //// public

    //// internal
    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply() + amount <= maxSupply,
            "ERC20: Mint over maxSupply limit"
        );
        require(msg.sender == i_owner, "ERC20: Owner is only minter");
        super._mint(account, amount);
    }

    //// private
    //// view / pure
}

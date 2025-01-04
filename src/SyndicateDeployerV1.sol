// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO
// Deployment factory contract to:
// keep a list of @p to token address + token version number
//// each @p gets only one token (can they overwrite? maybe they can chose on launch?)
// contract proxy address
// constructor values for: fee percentage, fee recipient (~tocwex TBA)
// access control list by TBA address (How do I do TBA lookup onchain?)
// upgradable contract proxy
// ownable deployment factory, but no control over the ledger

import {ISyndicateRegistry} from "./SyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {ISyndicateDeployerV1} from "./interfaces/ISyndicateDeployerV1.sol";

contract SyndicateDeployerV1 is ISyndicateDeployerV1 {
    // deploy function should call to the registry contract to:
    // check that the deployer is active
    // add the syndicate token to the registery
    // Structs: N/A

    // Variables
    // TODO Add natspec
    ISyndicateRegistry public immutable registry; // = "0x123..."; TODO hardcode the registry contract
    address public owner;
    address public pendingOwner;
    address public feeRecipient;

    // Mappings

    // Modifiers
    // TODO create 'isElligible' modifier?
    modifier onlyOwner() {
        require(msg.sender == owner, Unauthorized());
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, Unauthorized());
        _;
    }

    // Constructor
    constructor() {
        revert("Not yet implemented");
    }

    // Functions
    //// External functions
    // @inheritdoc ISyndicateDeployerV1
    function deploySyndicate(
        address tokenOwner,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory name,
        string memory symbol
    ) public returns (address syndicateToken) {
        // token logic
        // TODO: create 'isElligible' modifier?
        // require(
        //     owner == msg.sender,
        //     "Only the TBA of an L1 identity can launch a token"
        // );
        SyndicateTokenV1 syndicateTokenV1 = new SyndicateTokenV1(
            tokenOwner,
            initialSupply,
            maxSupply,
            name,
            symbol
        );
        emit TokenDeployed(address(syndicateTokenV1), tokenOwner);
        return address(syndicateTokenV1);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFee(uint256 fee) external onlyOwner {
        revert("Not yet implemented");
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFeeRecipient(
        address feeRecipient
    ) external returns (bool success) {
        revert("Not yet implemented");
    }

    /// @inheritdoc ISyndicateDeployerV1
    function checkFee() external view returns (uint256 fee) {
        revert("Not yet implemented");
    }

    /// @inheritdoc ISyndicateDeployerV1

    function checkOwner() external view returns (address deployerOwner) {
        revert("Not yet implemented");
    }

    /// @inheritdoc ISyndicateDeployerV1
    function updateOwner(
        address proposedOwner
    ) external onlyPendingOwner returns (address pendingOwner, address owner) {
        revert("Not yet implemented");
    }

    /// @inheritdoc ISyndicateDeployerV1
    function checkEligibility(address user) external view returns (bool) {
        // TODO Eligibility checks should vet: galaxy vs star vs galaxy planet vs planet vs L2
        // I'll probably need to include a local ERC6551 environment for this so until then
        // it likely just makes sense to check with the register if the proposed address already
        // exists in the registry
        revert("Not yet implemented");
    }

    //// Internal Functions
    //// TODO implement internal functions and include in external function wrappers
}

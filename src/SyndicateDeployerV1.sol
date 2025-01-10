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
// TODO implement receive and fallback Functions
import {ISyndicateRegistry} from "./SyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {ISyndicateDeployerV1} from "./interfaces/ISyndicateDeployerV1.sol";

contract SyndicateDeployerV1 is ISyndicateDeployerV1 {
    // Structs: N/A

    // Variables
    // TODO Add natspec
    address private immutable i_registry; // = "0x123..."; TODO hardcode the registry contract; does this need to be a struct or is it better just as the registry address?
    address private _owner;
    address private _pendingOwner;
    address private _feeRecipient;
    uint256 private _fee;

    // Mappings
    // TODO create mappings
    // Modifiers
    // TODO create 'isElligible' modifier?
    modifier onlyOwner() {
        require(msg.sender == _owner, Unauthorized());
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, Unauthorized());
        _;
    }

    // Constructor
    constructor() {
        i_registry = address(0);
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

    //// External functions

    // @inheritdoc ISyndicateDeployerV1
    function deploySyndicate(
        address tokenOwner,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory name,
        string memory symbol
    ) external returns (address syndicateToken) {
        return
            _deploySyndicate(
                tokenOwner,
                initialSupply,
                maxSupply,
                name,
                symbol
            );
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFee(uint256 fee) external onlyOwner {
        return _changeFee(fee);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFeeRecipient(
        address newFeeRecipient
    ) external returns (bool success) {
        return _changeFeeRecipient(newFeeRecipient);
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

    /// @inheritdoc ISyndicateDeployerV1
    function checkEligibility(
        address user
    ) external view returns (bool success) {
        // TODO Eligibility checks should vet: galaxy vs star vs galaxy planet vs planet vs L2
        // I'll probably need to include a local ERC6551 environment for this so until then
        // it likely just makes sense to check with the register if the proposed address already
        // exists in the registry
        return _checkEligibility(user);
    }

    function getRegistry() external view returns (address syndicateRegistry) {
        return i_registry;
    }

    function getOwner() external view returns (address deployerOwner) {
        return _owner;
    }

    function getPendingOwner() external view returns (address proposedOwner) {
        return _pendingOwner;
    }

    function getFeeRecipient() external view returns (address feeRecient) {
        return _feeRecipient;
    }

    function getFee() external view returns (uint256 fee) {
        return _fee;
    }

    //// Internal Functions
    function _deploySyndicate(
        address tokenOwner,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory name,
        string memory symbol
    ) internal returns (address tokenContract) {
        // token logic
        // deploy function should call to the registry contract to:
        // check that the deployer is active
        // add the syndicate token to the registery
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

    function _changeFee(uint256 fee) internal {
        _fee = fee;
        emit FeeUpdated(_fee);
    }

    function _changeFeeRecipient(
        address newFeeRecipient
    ) internal returns (bool success) {
        // change fee recipient logic
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

    function _checkEligibility(
        address user
    ) internal view returns (bool success) {
        address _user;
        user = _user;
        return true;
        // TODO actually implement eligibility checks via TBA value
    }
    //// TODO implement internal functions and include in external function wrappers
}

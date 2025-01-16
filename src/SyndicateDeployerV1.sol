// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

// TODO review all event emissions to ensure calldata is used instead of memory or loading from storage

import {SyndicateRegistry} from "./SyndicateRegistry.sol";
import {ISyndicateRegistry} from "./interfaces/ISyndicateRegistry.sol";
import {SyndicateTokenV1} from "./SyndicateTokenV1.sol";
import {ISyndicateDeployerV1} from "./interfaces/ISyndicateDeployerV1.sol";

contract SyndicateDeployerV1 is ISyndicateDeployerV1 {
    // Variables
    // TODO Add natspec
    ISyndicateRegistry private immutable i_registry;
    address private _owner;
    address private _pendingOwner;
    address private _feeRecipient;
    uint256 private _fee;

    // Mappings
    mapping(address => bool) _deployedSyndicates;

    // Modifiers
    // TODO create 'isElligible' modifier?

    modifier onlyOwner() {
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Unauthorized");
        _;
    }

    modifier validSyndicate() {
        require(_deployedSyndicates[msg.sender], "Unauthorized");
        _;
    }

    // Constructor
    constructor(address registryAddress, uint256 fee) {
        i_registry = ISyndicateRegistry(registryAddress);
        _owner = msg.sender;
        _feeRecipient = msg.sender;
        _fee = fee;
        emit DeployerV1Deployed(
            address(i_registry),
            _fee,
            _owner,
            _feeRecipient
        );
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
    //// TODO needs some sort of eligibility check for the azimuthPoint value against its relationship to msg.sender
    //// That check probably makes sense to occur here, or as a modifier?
    function deploySyndicate(
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 azimuthPoint,
        string memory name,
        string memory symbol
    ) external returns (address syndicateToken) {
        return
            _deploySyndicate(
                msg.sender,
                initialSupply,
                maxSupply,
                azimuthPoint,
                name,
                symbol
            );
    }

    function registerTokenOwnerChange(
        address syndicateToken,
        address newOwner
    ) external validSyndicate returns (bool success) {
        return _registerTokenOwnerChange(syndicateToken, newOwner);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFee(uint256 fee) external onlyOwner {
        return _changeFee(fee);
    }

    /// @inheritdoc ISyndicateDeployerV1
    function changeFeeRecipient(
        address newFeeRecipient
    ) external onlyOwner returns (bool success) {
        return _changeFeeRecipient(newFeeRecipient);
    }

    function proposeNewOwner(
        address proposedOwner
    ) external onlyOwner returns (bool success) {
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
    function isValidSyndicate(
        address user,
        uint256 azimuthPoint
    ) external view returns (bool success) {
        // TODO Eligibility checks should vet: galaxy vs star vs galaxy planet vs planet vs L2
        // I'll probably need to include a local ERC6551 environment for this so until then
        // it likely just makes sense to check with the register if the proposed address already
        // exists in the registry
        return _checkEligibility(user, azimuthPoint);
    }

    function validateTokenOwnerChange(
        address proposedTokenOwner,
        uint256 azimuthPoint,
        address tbaImplementation
    ) external view returns (bool isValid) {
        return
            _validateTokenOwnerChange(
                proposedTokenOwner,
                azimuthPoint,
                tbaImplementation
            );
    }

    function getRegistry() external view returns (address syndicateRegistry) {
        return address(i_registry);
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
        uint256 azimuthPoint,
        string memory name,
        string memory symbol
    ) internal returns (address tokenContract) {
        // TODO some check on eligibility either here or as a modifier in the external function to confirm ownership relationship of azimuthPoint == tokenOwner == msg.sender
        SyndicateTokenV1 syndicateTokenV1 = new SyndicateTokenV1(
            address(this),
            tokenOwner,
            initialSupply,
            maxSupply,
            azimuthPoint, // TODO determine how we get/validate azimuthPoint
            name,
            symbol
        );
        ISyndicateRegistry.SyndicateDeployerData
            memory syndicateDeployerData = i_registry.getDeployerData(
                address(this)
            );

        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry
            .Syndicate({
                syndicateOwner: tokenOwner,
                syndicateContract: address(syndicateTokenV1),
                syndicateDeploymentData: syndicateDeployerData,
                syndicateLaunchTime: block.number,
                azimuthPoint: azimuthPoint
            });

        _deployedSyndicates[address(syndicateTokenV1)] = true;
        i_registry.registerSyndicate(syndicate);
        emit TokenDeployed(address(syndicateTokenV1), tokenOwner);
        return address(syndicateTokenV1);
    }

    function _registerTokenOwnerChange(
        address syndicateToken,
        address newOwner
    ) internal returns (bool success) {
        success = i_registry.updateSyndicateOwnerRegistration(
            syndicateToken,
            newOwner
        );
        emit TokenOwnerChanged(syndicateToken, newOwner);
    }

    function _changeFee(uint256 fee) internal {
        _fee = fee;
        emit FeeUpdated(_fee);
    }

    function _changeFeeRecipient(
        address newFeeRecipient
    ) internal returns (bool success) {
        _feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated({feeRecipient: newFeeRecipient});
        success = true;
        return success;
    }

    function _proposeNewOwner(
        address proposedOwner
    ) internal returns (bool success) {
        _pendingOwner = proposedOwner;
        success = true;
        emit OwnerProposed({proposedOwner: proposedOwner});
        return success;
    }

    function _acceptOwnership() internal returns (bool success) {
        _owner = msg.sender;
        _pendingOwner = address(0);
        success = true;
        emit ProposalAccepted({newOwner: msg.sender});
        return success;
    }

    function _rejectOwnership() internal returns (bool success) {
        _pendingOwner = address(0);
        success = true;
        emit ProposalRejected({
            proposedOwner: msg.sender,
            deployerOwner: _owner
        });
        return success;
    }

    function _nullifyProposal() internal returns (bool success) {
        address proposedOwner = _pendingOwner;
        _pendingOwner = address(0);
        success = true;
        emit ProposalNullified({
            proposedOwner: proposedOwner,
            deployerOwner: msg.sender
        });
        return success;
    }

    function _renounceOwnership() internal returns (bool success) {
        _owner = address(0);
        emit OwnershipRenounced({previousOwner: msg.sender});
        success = true;
    }

    function _checkEligibility(
        address user,
        uint256 azimuthPoint
    ) internal view returns (bool success) {
        address _user;
        uint256 _azimuthPoint;
        _user = user;
        _azimuthPoint = azimuthPoint;
        return true;
        // TODO actually implement eligibility checks via TBA value
    }

    function _validateTokenOwnerChange(
        address proposedTokenOwner,
        uint256 azimuthPoint,
        address tbaImplementation
    ) internal view returns (bool isValid) {
        require(azimuthPoint < 65535, "Galaxys and Stars only, brokie");
        require(
            proposedTokenOwner == proposedTokenOwner,
            "Proposed token owner not valid"
        );
        require(
            tbaImplementation == tbaImplementation,
            "Proposed tba implemention somehow not valid..?"
        );
        isValid = true;
        // TODO figure out how to call out to ERC6551 registry
        // pseudocode for actually trying to validate address is a tba
        // tokenContract = azimuthContract address;
        // tokenID = azimuthPoint;
        // chainId = 1; // any considerations here for chainID?
        //// I think we can call the current chain's ID, or select an id manually depending on what we want to do
        // targetAddress = tbaRegistry.account(tbaImplementation, salt, chainId, tokenContract, tokenID);
        //// any considerations for the salt here? presumably if we use the 'default' salt, V1 tokens will only be able to be controlled by the default address of any given implementation. This probably isn't the end of the world...
        // require(targetAddress == proposedTokenOwner, "Not a valid TBA of your Urbit ID");
        return isValid;
    }
}

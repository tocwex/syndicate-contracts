// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

/// @title Interface for Syndicate Deployer
/// @author @thelifeandtimes
/// @notice deploys syndicate tokens associated with onchain Urbit identities
/// @dev dm ~sarlev-sarsen on urbit for details
interface ISyndicateDeployerV1 {
    // Events
    /// @notice emitted when a new token is deployed
    /// @dev
    /// @param token The syndicate token contract address
    /// @param owner The address associated with Urbit ID that launched token
    event TokenDeployed(address token, address owner);

    /// @notice emitted when owner updates the fee percentage
    /// @dev
    /// @param fee The minting fee as percentage
    event FeeUpdated(uint256 fee);

    event FeeRecipientUpdated(address feeRecipient);

    /// @notice emitted when ownership change is proposed
    /// @dev
    /// @param proposedOwner The address to become new owner
    /// @param deployerOwner The current owner and update proposer
    event OwnerProposed(address proposedOwner, address deployerOwner);

    event ProposalAccepted(address newOwner);

    /// @notice emitted when ownership change is rejected
    /// @dev
    /// @param proposedOwner The address rejected from the ownership proposal
    /// @param deployerOwner The address retaining ownership rights
    event ProposalRejected(address proposedOwner, address deployerOwner);

    event ProposalNullified(address proposedOwner, address deployerOwner);

    event OwnershipRenounced(address previousOwner);

    // Errors
    // TODO Add natspec
    error Unauthorized();

    // Functions
    /// @notice Called to deploy a syndicate token
    /// @dev
    /// @param tokenOwner eligibility checked address associated with onchain Urbit ID
    /// @param initialSupply The initial mint value
    /// @param maxSupply The hard cap on the ERC20 supply
    /// @param name The token name per ERC20 standard
    /// @param symbol The token symbol per ERC20 standard
    /// @return syndicateToken The token contract address just deployed
    function deploySyndicate(
        address tokenOwner,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory name,
        string memory symbol
    ) external returns (address syndicateToken);

    /// @notice Called to change protocol fee
    /// @dev function should be restricted to onlyOwner
    /// @param fee The fee percentage
    function changeFee(uint256 fee) external;

    /// @notice called to update the feeRecipient address
    /// @dev
    /// @param newFeeRecipient The address to recieve token distribution fee
    /// @return success The confirmation of the address being updated
    function changeFeeRecipient(
        address newFeeRecipient
    ) external returns (bool success);

    function proposeNewOwner(
        address proposedOwner
    ) external returns (address pendingOwner, address owner);

    function acceptOwnership() external returns (bool success);

    function rejectOwnership() external returns (bool success);

    function nullifyProposal() external returns (bool success);

    function renounceOwnership() external returns (bool success);

    /// @notice called to check the eligibility of an address to launch a token
    /// @dev function should check address association to onchain Urbit ID
    /// @param user The address of a potential token launcher, generally the function caller
    /// @return bool The eligibility of the user to launch a token
    function checkEligibility(address user) external view returns (bool);

    function getRegistry() external view returns (address syndicateRegistry);

    function getOwner() external view returns (address deployerOwner);

    function getPendingOwner() external view returns (address proposedOwner);

    function getFeeRecipient() external view returns (address feeRecient);

    function getFee() external view returns (uint256 fee);
}

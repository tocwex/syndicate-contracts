// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

//TODO: add "ownershipRejected" event

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
    /// @param deployerOwner The address that updated the fee
    event FeeUpdated(uint256 fee, address deployerOwner);

    event FeeRecipientUpdated(address feeRecipient);

    /// @notice emitted when ownership change is proposed
    /// @dev
    /// @param proposedOwner The address to become new owner
    /// @param deployerOwner The current owner and update proposer
    event OwnerProposed(address proposedOwner, address deployerOwner);

    /// @notice emitted when ownership change is accepted
    /// @dev
    /// @param newOwner as new address that accepted ownership
    event OwnerUpdated(address newOwner);

    // Errors
    // TODO Add natspec
    error Unauthorized();

    // Functions
    /// @notice Called to deploy a syndicate token
    /// @dev
    /// param tokenOwner eligibility checked address associated with onchain Urbit ID
    /// param initialSupply The initial mint value
    /// param maxSupply The hard cap on the ERC20 supply
    /// param name The token name per ERC20 standard
    /// param symbol The token symbol per ERC20 standard
    /// @return tokenContract The token contract address just deployed
    function deploySyndicate(
        address tokenOwner,
        uint256 initialSupply,
        uint256 maxSupply,
        string memory name,
        string memory symbol
    ) external returns (address tokenContract);

    /// @notice Called to change protocol fee
    /// @dev function should be restricted to onlyOwner
    /// params fee The fee percentage
    function changeFee(uint256 fee) external;

    /// @notice called to update the feeRecipient address
    /// @dev
    /// @param feeRecipient The address to recieve token distribution fee
    /// @return success The confirmation of the address being updated
    function changeFeeRecipient(
        address feeRecipient
    ) external returns (bool success);

    /// @notice called to check protocol fee
    /// @dev Likely to be better retrieved via the FeeUpdated event
    /// @return fee as uint256
    function checkFee() external view returns (uint256 fee);

    /// @notice Called to check the owner of the SyndicateDeployer contract
    /// @dev Likely to be better retrieved via the @OwnerUpdated event
    /// @return deployerOwner The address of the SyndicateDeployer contract
    function checkOwner() external view returns (address deployerOwner);

    /// @notice called to propose an update to the SyndicateDeployer contract owner
    /// @dev function should be restricted to onlyOwner
    /// @param proposedOwner The proposed new owner
    /// @return pendingOwner The address of the pendingOwner
    /// @return owner The address of the current owner
    function updateOwner(
        address proposedOwner
    ) external returns (address pendingOwner, address owner);

    /// @notice called to check the eligibility of an address to launch a token
    /// @dev function should check address association to onchain Urbit ID
    /// @param user The address of a potential token launcher, generally the function caller
    /// @return bool The eligibility of the user to launch a token
    function checkEligibility(address user) external view returns (bool);
}

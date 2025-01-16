// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

/// @title Interface for Syndicate Deployer
/// @author @thelifeandtimes
/// @notice deploys syndicate tokens associated with onchain Urbit identities
/// @dev dm ~sarlev-sarsen on urbit for details
interface ISyndicateDeployerV1 {
    // Events
    // TODO add natspec
    event DeployerV1Deployed(
        address indexed registryAddress,
        uint256 fee,
        address indexed owner,
        address feeRecipient
    );

    /// @notice emitted when a new token is deployed
    /// @dev
    /// @param token The syndicate token contract address
    /// @param owner The address associated with Urbit ID that launched token
    event TokenDeployed(address token, address owner);

    // TODO add natspec
    // TODO Do we want this to include the old owner?
    event TokenOwnerChanged(address indexed token, address newOwner);

    /// @notice emitted when owner updates the fee percentage
    /// @dev
    /// @param fee The minting fee as percentage
    event FeeUpdated(uint256 fee);

    // TODO Add natspec
    event FeeRecipientUpdated(address feeRecipient);

    /// @notice emitted when ownership change is proposed
    /// @dev
    /// @param proposedOwner The address to become new owner
    event OwnerProposed(address proposedOwner);

    // TODO Add natspec
    event ProposalAccepted(address newOwner);

    /// @notice emitted when ownership change is rejected
    /// @dev
    /// @param proposedOwner The address rejected from the ownership proposal
    /// @param deployerOwner The address retaining ownership rights
    event ProposalRejected(address proposedOwner, address deployerOwner);

    // TODO Add natspec
    event ProposalNullified(address proposedOwner, address deployerOwner);

    // TODO Add natspec
    event OwnershipRenounced(address previousOwner);

    // Errors
    // TODO Add natspec
    // error Unauthorized();

    // Functions
    /// @notice Called to deploy a syndicate token
    /// @dev
    /// @param initialSupply The initial mint value
    /// @param maxSupply The hard cap on the ERC20 supply; set to type(uint256).max for unlimited supply
    /// @param azimuthPoint The tokenID / @ud of the associated Urbit ID
    /// @param name The token name per ERC20 standard
    /// @param symbol The token symbol per ERC20 standard
    /// @return syndicateToken The token contract address just deployed
    function deploySyndicate(
        uint256 initialSupply,
        uint256 maxSupply,
        uint256 azimuthPoint,
        string memory name,
        string memory symbol
    ) external returns (address syndicateToken);

    // TODO add natspec
    function registerTokenOwnerChange(
        address syndicateToken,
        address newOwner
    ) external returns (bool success);

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

    // TODO add natspec
    function proposeNewOwner(
        address proposedOwner
    ) external returns (bool success);

    // TODO add natspec
    function acceptOwnership() external returns (bool success);

    // TODO add natspec
    function rejectOwnership() external returns (bool success);

    // TODO add natspec
    function nullifyProposal() external returns (bool success);

    // TODO add natspec
    function renounceOwnership() external returns (bool success);

    /// @notice called to check the eligibility of an address to launch a token
    /// @dev function should check address association to onchain Urbit ID
    /// @param user The address of a potential token launcher, generally the function caller
    /// @param azimuthPoint The @ud / tokenId of the provided TBA
    /// @return isValid The eligibility of the user to launch a token
    function isValidSyndicate(
        address user,
        uint256 azimuthPoint
    ) external view returns (bool isValid);

    // TODO add natspec
    function validateTokenOwnerChange(
        address proposedTokenOwner,
        uint256 azimuthPoint,
        address tbaImplementation
    ) external view returns (bool isValid);

    // TODO add natspec
    function getRegistry() external view returns (address syndicateRegistry);

    // TODO add natspec
    function getOwner() external view returns (address deployerOwner);

    // TODO add natspec
    function getPendingOwner() external view returns (address proposedOwner);

    // TODO add natspec
    function getFeeRecipient() external view returns (address feeRecient);

    // TODO add natspec
    function getFee() external view returns (uint256 fee);
}

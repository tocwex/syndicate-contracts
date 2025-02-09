// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

// TODO add natspec

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISyndicateTokenV1 {
    // Events
    event ContractAddedToWhitelist(address contractAddress);
    event contractRemovedFromWhitelist(address contractAddress);
    event OwnershipRenounced(address lastOwner, uint256 blockheight);
    event OwnershipTbaUpdated(
        address newOwner, address previousOwner, address tbaImplementation, bytes32 tbaSalt, uint256 blockheight
    );
    event SyndicateDissolved(uint256 blockHeight);
    event ProtocolFeeUpdated(uint256 newFee);
    event TokenMaxSupplySet(uint256 maxSupply);
    event MintingRightsRenounced(address tokenOwner);
    event ToggleDefaultWhitelist(address tokenOwner, bool defaultsWhitelisted);
    event MintFeeIncurred(address feeRecipient, uint256 fee);
    event BatchMintFeeIncurred(address feeRecipient, uint256 totalFees);

    // External functions
    function permissionedMint(address account, uint256 amount) external;

    function batchMint(address[] calldata account, uint256[] calldata amount) external;

    function permissionedBatchMint(address[] calldata account, uint256[] calldata amount) external;

    function updateOwnershipTba(address newOwner, address tbaImplementation, bytes32 salt) external returns (bool);

    function renounceMintingRights() external returns (bool sucess);

    function renounceOwnership() external returns (bool);

    function dissolveSyndicate() external returns (bool);

    function addWhitelistedContract(address contractAddress) external returns (bool);

    function removeWhitelistedContract(address contractAddress) external returns (bool);

    function reduceFee(uint256 newFee) external returns (bool);

    function setMaxSupply(uint256 setCap) external returns (bool);

    // View functions
    function getDeployerAddress() external view returns (address);

    function getMaxSupply() external view returns (uint256);

    function getAzimuthPoint() external view returns (uint256);

    function getMaxProtocolFee() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getOwner() external view returns (address);

    function isSupplyCapped() external view returns (bool);

    function isOwnerMintable() external view returns (bool);

    function getSyndicateStatus() external view returns (bool isCannonical);

    function usesDefaultWhitelist() external view returns (bool);

    function isWhitelistedContract(address) external view returns (bool);

    function getFeeRecipient() external view returns (address);
}

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19;

// TODO add natspec

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISyndicateTokenV1 {
    // Events
    event ContractAddedToWhitelist(address contractAddress);
    event contractRemovedFromWhitelist(address contractAddress);
    event OwnershipRenounced(address lastOwner);
    event OwnershipTbaUpdated(address newOwner);
    event SyndicateDissolved(uint256 blockHeight);
    event ProtocolFeeUpdated(uint256 newFee);

    // External functions
    function permissionedMint(address account, uint256 amount) external;

    function batchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) external;

    function permissionedBatchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) external;

    function updateOwnershipTba(
        address newOwner,
        address tbaImplementation,
        bytes32 salt
    ) external returns (bool);

    function renounceOwnership() external returns (bool);

    function dissolveSyndicate() external returns (bool);

    function addWhitelistedContract(
        address contractAddress
    ) external returns (bool);

    function removeWhitelistedContract(
        address contractAddress
    ) external returns (bool);

    function reduceFee(uint256 newFee) external returns (bool);

    // View functions
    function getDeployerAddress() external view returns (address);

    function getMaxSupply() external view returns (uint256);

    function getAzimuthPoint() external view returns (uint256);

    function getMaxProtocolFee() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getOwner() external view returns (address);

    function getSyndicateStatus() external view returns (bool isCannonical);

    function usesCustomWhitelist() external view returns (bool);

    function isWhitelistedContract(address) external view returns (bool);

    function getFeeRecipient() external view returns (address);
}

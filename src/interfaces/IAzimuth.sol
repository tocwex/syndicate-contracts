// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.25;

/// @title Azimuth owner function call interface
/// @dev In order to give a static `tokenContract` for ERC6551 tokenbound accounts, we need to call Azimuth's `owner()` method to retrieve the current address for Eclpitic which implements the `ownerOf()` method in compliance to the ERC721 standard
interface IAzimuth {
    /// @notice Function signature for owner of Azimuth.eth
    /// @dev Azimuth is owned by Ecplitic, and Ecplitic will replace itself as the owner with a new version upon upgrade, thus the `owner()` method should return the most current ecliptic address which implements the ERC721 standard.
    /// @return eclipticContract The contract address of the then-current version of ecliptic
    function owner() external view returns (address eclipticContract);
}

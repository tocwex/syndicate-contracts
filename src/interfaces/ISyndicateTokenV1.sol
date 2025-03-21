// SPDX-License-Identifier: GPLv3

pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Syndicate Fungible Token Contract Interface V1
/// @notice This is the interface for a SyndicateTokenV1 contract, to be launched from a SyndicateDeployerV1 factory contract and registered in the SyndicateRegistry contract
/// @dev All addresses registered in the SyndicateRegistry by a SyndicateDeployerV1 should be callable using this interface.
/// @custom:author ~sarlev-sarsen -- DM on the urbit network for further details

interface ISyndicateTokenV1 {
    ////////////
    // Events //
    ////////////

    ///@notice Emitted when a permissioned contract is added to the custom whitelist
    /// @dev Any address added to the custom whitelist must also be in the SyndicateDeployerV1 whitelist in order to function. The Custom whitelist is intended to allow a Syndicate Token owner to limit permissioned contracts to a subset of the officially permissioned contracts.
    /// @param tokenOwner The tokenbound account address that called the function to remove a contract from the whitelist
    /// @param contractAddress The address of the contract added to the whitelist
    event ContractAddedToWhitelist(
        address indexed tokenOwner,
        address indexed contractAddress
    );

    ///@notice Emitted when a permissioned contract is removed from the custom whitelist
    /// @dev Any address added to the custom whitelist must also be in the SyndicateDeployerV1 whitelist in order to function. The Custom whitelist is intended to allow a Syndicate Token owner to limit permissioned contracts to a subset of the officially permissioned contracts.
    /// @param tokenOwner The tokenbound account address that called the function to add a contract to the whitelist
    /// @param contractAddress The address of the contract added to  the whitelist
    event ContractRemovedFromWhitelist(
        address indexed tokenOwner,
        address indexed contractAddress
    );

    /// @notice Emitted when the syndicate owner renounces token ownership rights
    /// @dev
    /// @param lastOwner The TBA address which gave up ownership; This should always be controlled by the owner of the azimuthPoint
    /// @param blockheight The block.number at which the renounced ownership transaction is included
    event OwnershipRenounced(address indexed lastOwner, uint256 blockheight);

    /// @notice Emitted when the syndicate owner changes the ownership address of the Syndicate Token to a different TBA address
    /// @dev The owner will always be a derived address from the ERC6551 Registry, but may use a user provided implementation or salt should they so choose.
    /// @param newOwner The new ownership address to control the Syndicate Token contract
    /// @param previousOwner The owner transferring control to the new address
    /// @param tbaImplementation The address of the Tokenbound Account implementation to be used in the `account()` function of the ERC6551 Registry contract to validate ownership transfer validity
    /// @param tbaSalt The salt included in the TBA derivation
    /// @param blockheight The block.number at which the ownership change is included in a transaction
    event OwnershipTbaUpdated(
        address indexed newOwner,
        address indexed previousOwner,
        address tbaImplementation,
        bytes32 tbaSalt,
        uint256 blockheight
    );

    /// @notice Emitted when the syndicate owner dissolves a syndicate
    /// @dev This event is important to watch as it coincides with the Syndicate Token becoming 'noncannonical' and being removed from the SyndicateRegistry contract.
    /// @dev Dissolved Syndicates' tokens will continue to 'function' in that they can continue to be transferred, but they will no longer be legible to the registry contract, nor change the owner's tokenbound account implementation and a new Syndicate Token may be launched by the same Urbit ID to occupy that slot in the SyndicateRegistry contract.
    /// @dev To understand if a syndicate has been dissolved, call `getSyndicateStatus()` which will return the state of `_isCannonical.
    /// @param blockheight The block.number at which the Syndicate is dissolved and removed from the SyndicateRegistry
    event SyndicateDissolved(uint256 blockheight);

    /// @notice Emitted when the Syndicate contract ecosystem owner changes the protocol fee
    /// @dev This value should always be less than the previous protocol fee
    /// @param newFee The new fee to be incurred on a permissionless mint by the Syndicate owner
    event ProtocolFeeUpdated(uint256 newFee);

    /// @notice Emitted when the Syndicate Token has a max supply set
    /// @dev The max supply may be set in the initial contract deployment, or at any later point
    /// @dev If not set prior to renouncing ownership, it will be set to `type(uint256).max` upon renouncing and any further minting and changes to totalSupply will need to be handled by any permissioned contracts added to the `SyndicateDeployerV1` contract.
    /// @param maxSupply The set value for the maximum supply of the token.
    event TokenMaxSupplySet(uint256 maxSupply);

    /// @notice Emitted when the Syndicate Token Owner renounced minting rights
    /// @dev This does not mean there is no ability for the contract to do further mints, just that any future mints must be done by a permissioned contract.
    /// @dev The minting rights state may be used by a permissioned contract to ensure that token supply is not unexpectedly modified outside of the context of a permissioned contract
    /// @param tokenOwner The address which renounced the minting rights
    event MintingRightsRenounced(address indexed tokenOwner);

    /// @notice Emitted when the Syndicate Token changes the access controls for the default permissioned contracts
    /// @dev If defaultWhitelist is true, any contract in the SyndicateDeployerV1 whitelist is able to interact with the permissioned minting functions of the SyndicateTokenV1; if false, contracts must also be on the SyndicateTokenV1 whitelist as well.
    /// @param tokenOwner The address which changed the state of the access controls for the default whitelist
    /// @param defaultsWhitelisted the boolean indicating the permission state of the default whitelist
    event ToggleDefaultWhitelist(
        address indexed tokenOwner,
        bool defaultsWhitelisted
    );

    /// @notice Emitted when a minting fee is incurred
    /// @param feeRecipient The address to recieve the fee
    /// @param fee The amount sent to the fee recipient
    event MintFeeIncurred(address indexed feeRecipient, uint256 fee);

    /// @notice Emitted when a minting fee is incurred via a batch mint
    /// @dev Transfer events are emitted for each transfer in a batch mint, but each batch will only have one mint fee transfer and one mint fee event
    /// @param feeRecipient The address to recieve the fee
    /// @param totalFees The sum total amount of fees sent to the fee recipient
    event BatchMintFeeIncurred(address indexed feeRecipient, uint256 totalFees);

    ////////////////////////
    // External functions //
    ////////////////////////

    /// @notice Permissioned singular mint
    /// @dev The permissionedMint function should be access controlled as it allows modification of the token supply and transfer of tokens to arbitrary accounts
    /// @dev Permissioned mint functions are intended to be called only by contract addresses whitelisted by the SyndicateDeployerV1 contract and allowed by the Syndicate Token owner
    /// @param account The address to recieve the newly minted tokens
    /// @param amount The amount of tokens to mint, with 18 decimals
    function permissionedMint(address account, uint256 amount) external;

    /// @notice Batch mint
    /// @dev batchMint does not do checks for array length so it is possible to run out of gas
    /// @param account An array of addresses to recieve newly minted tokens
    /// @param amount An array of amounts to mint, with 18 decimals
    function batchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) external;

    /// @notice Permissioned batch mint
    /// @dev The permissionedBatchMint function should be access controlled as it allows modification of the token supply and transfer of tokens to arbitrary accounts
    /// @dev Permissioned mint functions are intended to be called only by contract addresses whitelisted by the SyndicateDeployerV1 contract and allowed by the Syndicate Token owner
    /// @dev permissionedBatchMint does not do checks for array length so it is possible to run out of gas
    /// @param account An array of addresses to recieve newly minted tokens
    /// @param amount An array of amounts to mint, with 18 decimals
    function permissionedBatchMint(
        address[] calldata account,
        uint256[] calldata amount
    ) external;

    /// @notice Ownership address update functionality
    /// @dev This is validated against the isValidTBA modifier of the SyndicateDepoyerV1 contract, but there is no controls over what tbaImplementation address is provided or the contract logic deployed at that address.
    /// @dev Syndicate token owners may use *any* tbaImplementation, but should note that unvetted implementations may make it possible to lose control of the Syndicate Token
    /// @param newOwner The intended new ownership address
    /// @param tbaImplementation The address to use in validation that the newOwner address is a tokenbound account address of the Urbit ID associated with the Syndicate Token
    /// @param salt Any user provided bytes32 value to use in address validation; using the default value is recommended unless explicitly desirable to use a custom salt
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function updateOwnershipTba(
        address newOwner,
        address tbaImplementation,
        bytes32 salt
    ) external returns (bool success);

    /// @notice Owner address renounces minting rights
    /// @dev This function irrevokably renounces the minting rights of the current and any future owners of the Syndicate Token, but it does not prevent any further mints entirely, as it does not block minting by permissioned contracts using the permissioned mint functions
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function renounceMintingRights() external returns (bool success);

    /// @notice Owner address renounces ownership completely
    /// @dev Renouncing ownership prevents the owner from minting, setting the max total supply of the token, adding or removing permissioned contracts, modifying the default whitelist permissioned, updating the ownership tokenbound account address, and/or dissolving the syndicate.
    /// @dev A Syndicate token whose owner has renounced ownership will forever be the cannonical Syndicate Token for that Urbit ID
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function renounceOwnership() external returns (bool success);

    /// @notice Removes the Syndicate from the SyndicateRegistry
    /// @dev Dissolving the Syndicate Token will remove it from the SyndicatRegistry contract, as well as irrevokably set the _isCannonical value to false.
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function dissolveSyndicate() external returns (bool success);

    /// @notice Adds a contract to the Syndicate Token permissioned mint whitelist
    /// @dev Allows a Syndicate Token owner to have more precise controls over the permissioned contracts which have access to the permissionedMint and permissionedBatchMint functions of the Syndicate Token contract
    /// @dev To save gas cost and contract call complexity input param is not validated against the SyndicateDeployerV1's whitelist but addresses added here are to be a subset of that whitelist in order to function
    /// @param contractAddress The address of a contract in the SyndicateDeployerV1 whitelist which should have access to the minting functions of the SyndicateTokenV1
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function addWhitelistedContract(
        address contractAddress
    ) external returns (bool success);

    /// @notice Adds a contract to the Syndicate Token permissioned mint whitelist
    /// @dev Allows a Syndicate Token owner to have more precise controls over the permissioned contracts which have access to the permissionedMint and permissionedBatchMint functions of the Syndicate Token contract
    /// @dev To save gas cost and contract call complexity input param is not validated against the Syndicate Token's existing whitelist so checking existing whitelisted contracts should be done by looking at past events emitted by the token contract
    /// @param contractAddress The address of a contract to be removed from the Syndicate Token's whitelist
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function removeWhitelistedContract(
        address contractAddress
    ) external returns (bool success);

    /// @notice Toggles the permissions of the default SyndicateDeploverV1 whitelist
    /// @dev If the default whitelist state is true, any address in the permissioned contract mapping will be able to call the Syndicate Token permissioned mint functions; by setting it to false, only a subset of contracts--those added by the Syndicate Token owner--will be able to call those functions. This is set to false by default to ensure Syndicate Token owners need to turn it on in order to let *any* permissioned contracts mint on behalf of their Syndicate.
    /// @param state The desired state of the whitelist perms; true allows the default whitelist, false provides the tighter access controls
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function toggleDefaultWhitelist(bool state) external returns (bool success);

    /// @notice Allows the Syndicate contract ecosystem owner to reduce the protocol fee
    /// @dev The protocol fee incurred by mint and batchMint functions can be reduced but not increased by the Syndicate contract ecosystem owner on a case by case basis.
    /// @param newFee The amount of the new fee, in basis points (i.e. 300 is a 3% fee)
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function reduceFee(uint256 newFee) external returns (bool success);

    /// @notice Irrevokably set the max token supply
    /// @dev If not set upon launch, this can be separately called by the owner to set an immutable maxSupply
    /// @dev If an owner renounces ownership, maxSupply will be set to the current value. If `_setCap` is false, you may want to ask the user if they want to set a max supply before renouncing ownership
    /// @param setCap The value to irrevokably set as the `_maxSupply`
    /// @return success Whether the function succeeded; recieving a false would be unexpected as the intended behavior is for a transaction to revert instead
    function setMaxSupply(uint256 setCap) external returns (bool success);

    ////////////////////
    // View functions //
    ////////////////////

    /// @notice Gets the address of the related SyndicateDeployerV1 contract
    /// @return deployerAddress The address of a SyndicateDeployerV1 contract which should be callable with the ISyndicateDeployerV1 interface
    function getDeployerAddress()
        external
        view
        returns (address deployerAddress);

    /// @notice Gets the max supply of the Syndicate Token
    /// @return maxSupply the amount of max supply with 18 decimals
    function getMaxSupply() external view returns (uint256 maxSupply);

    /// @notice Gets the azimuth point associated with this Syndicate Token
    /// @dev This uint256 is the tokenId of an ERC721 from Urbit's Azimuth Contract
    /// @dev This is also the @ud of an Urbit 'ship' on the Urbit Network. Contacting the Syndicate Token Owner can be done by getting on the urbit network and sending a message to `@p`<tokenId>
    /// @return azimuthPoint The tokenId of the Urbit ID associated with this Syndicate
    function getAzimuthPoint() external view returns (uint256 azimuthPoint);

    /// @notice Gets the max protocol fee
    /// @dev This value is set on contract creation by the SyndicateDeployerV1 contract's then-current protocol fee value
    /// @return maxFee The protocol fee amount in basis points (i.e. 300 is a 3% fee)
    function getMaxProtocolFee() external view returns (uint256 maxFee);

    /// @notice Gets the current protocol fee
    /// @return currentFee The current protocol fee amount in basis points (i.e. 300 is a 3% fee)
    function getProtocolFee() external view returns (uint256 currentFee);

    /// @notice Gets the current Syndicate Token owner address
    /// @return syndicateOwner The address with ownership permissions for the Syndicate Token contract
    function getOwner() external view returns (address syndicateOwner);

    /// @notice Checks if a supply cap is set
    /// @dev This should be used in conjunction with `getMaxSupply()` to determine if the token is capped
    /// @dev If a token has a maxSupply of `type(uint256).max` but `isSupplyCapped` returns true, that means it will always have an infinite supply,
    /// @dev If `isSupplyCapped()` returns false it means the supply cap may be set at a later date
    /// @return isCapped The boolean indicating if supply is capped
    function isSupplyCapped() external view returns (bool isCapped);

    /// @notice Checks if owner has minting permissions
    /// @dev Even if the owner maintains minting permissions, they can never override the maxSupply of the Syndicate Token
    /// @return ownerMintable The boolean indicating if the owner has minting rights
    function isOwnerMintable() external view returns (bool ownerMintable);

    /// @notice Checks if Syndicate Token is cannonical for it's Urbit ID
    /// @dev Syndicate's which are non-cannonical should generally be disregarded as irrelevant and treated as illegitimate. To find the legitimate Syndicate for a given Urbit ID, call the SyndicateRegistry contract with the tokenId of that Urbit
    /// @return isCannonical The boolean indicating cannonicity
    function getSyndicateStatus() external view returns (bool isCannonical);

    /// @notice Checks if Syndicate Token uses the default permissioned contract whitelist
    /// @dev If a Syndicate Token is using the default whitelist, checks for the custom whitelist are bypassed and to confirm a contract will be able to call the Syndicate Token's minting functions you should query the SyndicateDeploverV1 contract.
    /// @return usesDefault The boolean indicating if the default whitelist is used
    function usesDefaultWhitelist() external view returns (bool usesDefault);

    /// @notice Checks if a contract is in the custom whitelist
    /// @dev These contract addresses are stored in a mapping, so please track event emissions to maintain an index of whitelisted contracts for a given Syndicate Token contract
    /// @param contractAddress The address of a contract to be checked against the Syndicate Token's custom whitelist
    /// @return isWhitelisted The boolean indicating if the contract is whitelisted
    function isWhitelistedContract(
        address contractAddress
    ) external view returns (bool isWhitelisted);

    /// @notice checks the fee recipient of minting fees
    /// @dev Calls the SyndicateDeployerV1 contract to check fee recipeint address
    /// @return feeRecipient The address provided by the SyndicateDeployerV1 contract
    function getFeeRecipient() external view returns (address feeRecipient);
}

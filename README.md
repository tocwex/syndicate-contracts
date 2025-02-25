The Syndicate contract ecosystem is designed to interface with Urbit ID via the Azimuth and Ecliptic contracts. Ecliptic is an ERC721 compatible contract, while Azimuth is the datastore which Ecliptic references and modifies to implement the functionality within the Urbit ID contract ecosystem. The Syndicate contracts rely on the ERC6551 / EIP6551 tokenbound standard in order to implement a smart contract ecosystem where contract accounts are controlled by Urbit IDs and permissioned to launch ERC20 tokens that are canonically linked to the Urbit ID that generated them. There are three main parts of the Syndicate contract ecosystem:

1. SyndicateRegistry - intended to be the canonical registry of Syndicate Tokens, it is a singleton contract from which all other contract relationships can be derived. It holds the valid set of Deployer factory contracts and is the place to look up the relationships between Urbit ID tokenIds and their syndicate tokens. The registry should only be modifiable by valid Deployer Contracts, plus have administrative actions controlled by the Owner. The other important thing to call out here is that the registry implements the IERC721 interface in order to provide a static point for ERC6551's `tokenContract` parameter, but it pulls ownership logic through Azimuth from Ecliptic in order to properly vet the owner of a given `tokenId` for Urbit ID.
2. SyndicateDeployerV1 - This is the first in a series of factory contracts that can be permissioned to deploy and register Syndicate Tokens. It should enforce the logic of what accounts are allowed to launch tokens from it's factory, and record them in the registry contract. It is only capable of deploying a SyndicateTokenV1 contract, and tracking a list of permissioned contracts which can interact with the SyndicateTokenV1 contracts.
3. SyndicateTokenV1 - This is a basic ERC20 token controlled by the tokenbound account of an Urbit ID and registered in the SyndicateRegistry contract via the SyndicateDeployerV1 contract. It should be securely controlled by it's owner, which should only be modifiable to another valid tokenbound account.

Please contact ~sarlev-sarsen on urbit if you have any questions about this project, or join our public group at ~tocwex/syndicate-public.

# About

This repo uses Foundry Ethereum development tools and the OpenZepplin contracts as a baseline.

See the `.env.example` file for a starting point of the environment variables you will need to provide in order to run deployment scripts, tests, etc.

A `Makefile` is provided for more concise running of commands, but it's usefulness is not guaranteed at any given point in time.

For development purposes, we will be using `pragma solidity ^0.8.19`, but prior to release will lock down the solidity version, likely to 0.8.25

## TODOS

- [x] Add eligibility check on uint256 azimuthPoint claiming and association with ownership addresses and SyndicateTokenV1 contract launching
- [x] Deployment Contract test cases
- [x] Robust testing suite
- [x] Finish natspec documentation for interfaces
- [x] Finish natspec documentation for contract code
- [x] Decide on upgrade to v5.0.0 of OpenZepplin contracts or not
- [x] Further gas optimization
- [x] OPTIONAL: Look into Proxy and Upgradeable Proxy possibilities
- [x] Add beta launch whitelisting functionality
- [ ] lock pragma solidity versions

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

See the `.env.example` file to properly set up your environment, and see the `Makefile` to have some core commands. Most useful are:

- `make test-wip`: run test suite with verbose output for any tests with `WIP` in their name
- `make deploy-sepolia-pk`: deploy contract suite to Sepolia and verify contracts on etherscan

## Dependencies

This repo uses the ERC6551 and OpenZepplin contracts as dependencies.

## Frontend interfaces

See the `tocwex/slab` repo for the default frontend interface for the Syndicate contract ecosystem. It is worth noting that while the Syndicate contracts have no dependency on the Gnosis Safe ecosystem, we do use Safe multisigs in the broader %slab implementation, which requires a modified IERC6551Account implementation that supports two different versions of IERC1271 signing method. Please reach out to ~sidnym-ladrut on urbit if you have any questions on this front.

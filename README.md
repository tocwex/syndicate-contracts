This repo is the workspace for development of the Syndicate contract ecosystem.

This repo uses Foundry Ethereum development tools and the OpenZepplin contracts as a baseline. It also includes the ERC6551 Tokenbound Account standard which is used to create a 1:1 mapping of Urbit ID to smart contract wallet.

See the `.env.example` file for a starting point of the environment variables you will need to provide in order to run deployment scripts, tests, etc.

The contracts launched to mainnet use the `pragma solidity 0.8.25`.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

You can use all the relevant Foundry commands (i.e. `forge build`, `forge test`, etc), and more detail can be found at https://book.getfoundry.sh/. In addition to the standard foundry commands, a `Makefile` is provided for more concise running of commands; Modify it to your needs.

If you have questions, or need help, get on urbit and send a DM to ~sarlev-sarsen. If you can't figure out how to get on urbit, you probably aren't trying hard enough and it is unlikely that bothering us about this code will be worthwhile. For more on the intent behind the Syndicate project, read the section below.

# Syndicates: operational unification of onchain and offchain

Syndicates are portable digital organizations designed for 'network tribes' that value decentralization, personal sovereignty, and collective innovation. Critical to this purpose is the ability to make onchain activity map more accurately to offchain operations.

Through a combination of onchain digital assets and tools (such as the Ethereum smart contracts in this repository), along with off-chain software running over a peer-to-peer and end-to-end encrypted network (using [Urbit](https://urbit.org)), Syndicates are able to operate as self-sovereign socioeconomic networks, both onchain _and offchain_.

The onchain element of a Syndicate takes full advantage of the permissionless composability of open blockchains, integrating this Syndicate contract ecosystem with:

- Urbit ID non-fungible tokens for identity and p2p networking
- Tokenbound Account smart wallets for identity-linked transactions
- Gnosis Safe multisigs and ENS domains for ecosystem compatibility

  These technologies give us a way to manage onchain assets and governance, doing anything you may see from a web3 DAO:

- Peer-to-peer token transfers
- Pseudonymous asset ownership
- Shared control of treasury assets
- Trustless rights enforcement

  The cornerstone, though, is how we create a link between the onchain and offchain. If your onchain network is a collection of addresses, tokens, and cryptographic keys, your offchain network is a collection of actors coordinating across a blend of 'official' and unofficial digital and analog mediums looking to onchain digital artifacts as a representation of value and credibility. Unfortunately, In the current landscape, the state of offchain networks is somewhere between 'tenuous' and 'entirely non-existent'.

This is important because the socioeconomic strength of any given web3 organization must be assessed with a mind to the validity of the connection between these two networks. If the onchain consensus doesn't have a valid connection to the offchain operation (decentralized or otherwise), what good is the consensus as a indicator of operational capacity to impact the future on behalf of digital rights holders? Syndicates enhance the validity of this connection by inextricably linking your onchain shelling point to your offchain shelling point.

Of course, as a singular on-chain NFT, how do you build an on-chain network around an individual Urbit ID? It's a little bit difficult for a network to belong to everyone if there is only a single point of control.

Through tokenbound accounts, a canonical Syndicate Registry, and an extensible plugin system of token deployment factories and programmatic minting contracts, the Syndicate contract ecosystem creates a 'finite tokenspace' that creates a 1:1 mapping of ERC20 "Syndicate Tokens" and Urbit Identities. This does two key things:

- Allows fractionalization of an individual non-fungible token, enabling onchain signaling and participation in specific Syndicate communities
- Protects against the proliferation of shitcoin scams, pump and dumps, or other wasteful spam

  The onchain Syndicate Registry records relationships between Urbit IDs and Syndicate Token contract addresses, ensuring that community members and prospective token holders can transparently understand the connection between a given ERC20 token, an Urbit ID, and it's off-chain networked computer. No need to rely on a centralized memecoin platform that centrally hosts off-chain content. No need to hope that you are following the right account on twitter. No wishing that you didn't have to join yet another Telegram chat.

Interested in acquiring a particular Syndicate Token? Just send them a peer-to-peer message. Maybe they have a public group you can join, maybe they have some software you can download, or maybe they aren't even online (in which case, maybe you want to stay away).

What does a Syndicate Token _do?_ Who knows. Maybe it's an internal reputation system for community members. Maybe it's a governance token that controls software updates. Maybe it's used to gate access to custom software or private group chats. That's up to the Syndicate itself. All we know is it the token, the identity, and the networked computer give the Syndicate a unified presence across onchain and offchain networks.

Regardless of what you might _do_ with them, Syndicates are your way to unify your onchain digital rights with your offchain digital coordination. So go forth and build something with your tribe.

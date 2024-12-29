This repo is the workspace for development of the Syndicate contract ecosystem.

This repo uses Foundry Ethereum development tools and the OpenZepplin contracts as a baseline.

See the `.env.example` file for a starting point of the environment variables you will need to provide in order to run deployment scripts, tests, etc.

A `Makefile` is provided for more concise running of commands, but it's usefulness is not guaranteed at any given point in time.

For development purposes, we will be using `pragma solidity ^0.8.19`, but prior to release will lock down the solidity version, likely to 0.8.25

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

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

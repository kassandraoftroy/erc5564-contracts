# ERC5564 Contracts

ERC5564 contracts for stealth addresses on evm chains are finally here!

## Core Contracts

The canonical contracts for ERC5564 compliant stealth-address schemes are deployed to mainnets.

`ERC5564Announcer` - The canonical, shared, announcer contract that announces a stealth address payment

`ERC5564Registry` - Optional (opt-in) registry to register a stealth meta address

See official implementation and deployments [here](https://github.com/ScopeLift/stealth-address-erc-contracts)

## ERC5564Direct

This repo is an example integration with the core contracts. It contains:

`ERC5564Direct` - Transfer any ERC20 or ERC721 directly to a stealth address and announce it. Uses an extended metatdata schema and has convenience methods for parsing and creating metadata to attach to announcements. Uses a minimum native Transfer amount as rate-limiter and to ensure owners have funds to pay gas and sweep/claim tokens from the stealth addresses later.

NOT AUDITED - HOMEROLLED CRYPTO - USE AT YOUR OWN RISK

## Installation

```
forge install
```

## Test

NOTE: fill in `.env` see `.env.example` before running tests

```
forge test -vv
```

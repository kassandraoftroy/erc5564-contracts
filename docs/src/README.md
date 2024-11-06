# ERC5564 Contracts

ERC5564 is the main ERC defining the stealth addresses standard for ethereum. It recently got included. Let's build on it!

## Core Contracts

**UPDATE:** This repo no longer implements a clone of ERC5564 and ERC6538 core contracts. Now that the canonical implementations have been audited and deployed. [Find official implementation and deployments here](https://github.com/ScopeLift/stealth-address-erc-contracts)

`ERC5564Announcer.sol` - The canonical, shared, announcer contract that announces a stealth address payment. [source code](https://github.com/ScopeLift/stealth-address-erc-contracts/blob/main/src/ERC5564Announcer.sol)

`ERC6538Registry.sol` - Optional (opt-in) registry to register a stealth meta address. [source code](https://github.com/ScopeLift/stealth-address-erc-contracts/blob/main/src/ERC6538Registry.sol)

## Stealthereum

This repo is an example integration with the core ERC contracts. It implements a set of patterns and an extended schema for metadata on announcements.

`Stealthereum.sol` - Transfer any ERC20 or ERC721 directly to a stealth address and announce it. Has convenience methods for parsing and creating metadata to attach to announcements.

`StealthSwapHelper.sol` - First swap tokens (or ETH) for an ERC20 token, then forward the resulting tokens to a stealth address of your choosing (and announce it).

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

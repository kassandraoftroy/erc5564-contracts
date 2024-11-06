# Stealth.ereum: ERC5564 Contracts

ERC5564 is the main ERC defining the stealth addresses standard for ethereum. It recently got included. Let's build on it!

**UPDATE:** This repo no longer implements core contracts [ERC5564Announcer.sol](https://github.com/ScopeLift/stealth-address-erc-contracts/blob/main/src/ERC5564Announcer.sol) and [ERC6538Registry.sol](https://github.com/ScopeLift/stealth-address-erc-contracts/blob/main/src/ERC6538Registry.sol). Canonical implementations were created, audited and deployed by ScopeLift, so we choose to inherit their [repo](https://github.com/ScopeLift/stealth-address-erc-contracts) as a dependency here.

## Stealthereum

Stealth.ereum is an example integration with the core ERC5564 contracts. It implements a set of patterns and an extended schema for metadata on announcements.

`Stealthereum.sol` - Transfer ETH and/or any ERC20 and/or any ERC721 directly to a stealth address and announce it. You can send as many different tokens to a certain stealthMetaAddress that you like in one call. We have convenience methods for parsing and creating metadata to attach to announcements.

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

## Docs

run docs locally with

```
forge doc --serve --port 4000
```

then navigate to https://localhost:4000

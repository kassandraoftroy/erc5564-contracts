# Stealth.ereum: ERC5564 Contracts

ERC5564 is the main ERC defining the stealth addresses standard for ethereum. It recently got included. Let's build on it!

**UPDATE:** This repo no longer implements core contracts [ERC5564Announcer.sol](https://github.com/ScopeLift/stealth-address-erc-contracts/blob/main/src/ERC5564Announcer.sol) and [ERC6538Registry.sol](https://github.com/ScopeLift/stealth-address-erc-contracts/blob/main/src/ERC6538Registry.sol). Canonical implementations were created, audited and deployed by ScopeLift, so we choose to inherit their [repo](https://github.com/ScopeLift/stealth-address-erc-contracts) as a dependency here.

## Stealth.ereum

Stealth.ereum is the general banner for a suite of free an open source tools and products that further ERC5564 stealth address usage and adoption (!! See and support our wallet initiative project funding page on Giveth.io [here](https://giveth.io/es/project/cypherpunk-wallet) !!). This repo is an opinionated smart contract integration with ERC5564 protocol. It implements a simple "direct batch transfer" pattern for stealth address usage and has an extended schema for metadata posted with announcements.

`Stealthereum.sol` - Transfer ETH and/or any ERC20 and/or any ERC721 directly to a stealth address and announce it on the canonical `ERC5564Announcer`. You can batch send as many different tokens to a certain stealth address as you like. Metadata is automatically encoded onchain before announcement, and we have a convenience method for parsing metadata that fits our schema.

`StealthSwapHelper.sol` - First swap tokens (or ETH) for an ERC20 token, then forward the resulting tokens to a stealth address of your choosing and announce the stealth transfer.

## Design Decisions

We deliberately made the decision to send _directly_ to stealth addresses, rather than use any "fancy" interstitial smart contracts or account abstraction. This may not be perfect UX (see next paragraph), but it also makes Stealth Addresses more _legible_ to the average user. The funds go straight to the freshly created address. If you can "find" the private key (from the announcement data and your stealth key), you can access the funds in your stealth address, no holds barred, no need to understand any further protocols or assumptions.

Given the chosen architecture, **users likely want to forward native ETH with every stealth address payment** so that the receiver can operate the address when they need to without breaking anonymity (by sending ETH to the address with a doxxed wallet).

We are quite hopeful that this UX issue can be improved markedly with [EIP-7702](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-7702.md)

## Extended Metadata format

Here is the suggestion about how to use metadata from the EIP:

```solidity
  /// Besides the view tag, the metadata can be used by the senders however they like, 
  /// but the below guidelines are recommended:
  /// The first byte of the metadata MUST be the view tag.
  /// - When sending/interacting with the native token of the blockchain (cf. ETH), the metadata SHOULD be structured as follows:
  ///     - Byte 1 MUST be the view tag, as specified above.
  ///     - Bytes 2-5 are `0xeeeeeeee`
  ///     - Bytes 6-25 are the address 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE.
  ///     - Bytes 26-57 are the amount of ETH being sent.
  /// - When interacting with ERC-20/ERC-721/etc. tokens, the metadata SHOULD be structured as follows:
  ///   - Byte 1 MUST be the view tag, as specified above.
  ///   - Bytes 2-5 are a function identifier. When a function selector (e.g.
  ///     the first (left, high-order in big-endian) four bytes of the Keccak-256
  ///     hash of the signature of the function, like Solidity and Vyper use) is
  ///     available, it MUST be used.
  ///   - Bytes 6-25 are the token contract address.
  ///   - Bytes 26-57 are the amount of tokens being sent/interacted with for fungible tokens, or
  ///     the token ID for non-fungible tokens.
```

since in our architecture we could send a batch of tokens as well as ETH to the stealth address all at once, we extend this metadata schema as follows:

```solidity
    /// @dev METADATA SPEC: the first (n)(56)+1 bytes of metadata MUST conform to the following format (where `n` is number of native or token transfers).
    /// First byte MUST be a view tag (if no view tag, can be any arbitrary byte but should be 0x00).
    /// IF forwarding the native token (e.g. ETH) next 56 bytes MUST be 24 bytes of 0xee + 32 byte uint matching msg.value.
    /// Next 56 byte chunks MAY start with 0x23b872dd (transferFrom) to be considered a token transfer.
    /// These token transfer 56 byte chunks go 0x23b872dd + 20 byte token address + 32 byte uint of amount/tokenId to transfer.
    /// Once the start of a 56 byte chunk does not start with 0x23b872dd, we consider this unstructured appended data.
```

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

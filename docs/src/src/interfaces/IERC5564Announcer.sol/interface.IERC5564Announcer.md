# IERC5564Announcer
[Git Source](https://github.com/kassandraoftroy/erc5564-contracts/blob/17f8300a258dafc126636bf4c6b2cff57409473e/src/interfaces/IERC5564Announcer.sol)

NOTE very slight adaptation to code found here https://eips.ethereum.org/EIPS/eip-5564

Interface for announcing when something is sent to a stealth address.


## Functions
### announce

*Called by integrators to emit an `Announcement` event.*


```solidity
function announce(uint256 schemeId, address stealthAddress, bytes memory ephemeralPubKey, bytes memory metadata)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemeId`|`uint256`|The integer specifying the applied stealth address scheme.|
|`stealthAddress`|`address`|The computed stealth address for the recipient.|
|`ephemeralPubKey`|`bytes`|Ephemeral public key used by the sender.|
|`metadata`|`bytes`|An arbitrary field MUST include the view tag in the first byte. Besides the view tag, the metadata can be used by the senders however they like, but the below guidelines are recommended: The first byte of the metadata MUST be the view tag. - When sending/interacting with the native token of the blockchain (cf. ETH), the metadata SHOULD be structured as follows: - Byte 1 MUST be the view tag, as specified above. - Bytes 2-5 are `0xeeeeeeee` - Bytes 6-25 are the address 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE. - Bytes 26-57 are the amount of ETH being sent. - When interacting with ERC-20/ERC-721/etc. tokens, the metadata SHOULD be structured as follows: - Byte 1 MUST be the view tag, as specified above. - Bytes 2-5 are a function identifier. When a function selector (e.g. the first (left, high-order in big-endian) four bytes of the Keccak-256 hash of the signature of the function, like Solidity and Vyper use) is available, it MUST be used. - Bytes 6-25 are the token contract address. - Bytes 26-57 are the amount of tokens being sent/interacted with for fungible tokens, or the token ID for non-fungible tokens.|


## Events
### Announcement
*Emitted when sending something to a stealth address.*

*See the `announce` method for documentation on the parameters.*


```solidity
event Announcement(
    uint256 indexed schemeId,
    address indexed stealthAddress,
    address indexed caller,
    bytes ephemeralPubKey,
    bytes metadata
);
```


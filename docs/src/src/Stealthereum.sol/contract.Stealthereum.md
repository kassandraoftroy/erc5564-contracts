# Stealthereum
[Git Source](https://github.com/kassandraoftroy/erc5564-contracts/blob/9c7474868e718b99a2359579698b9994ca0ad2e8/src/Stealthereum.sol)

**Inherits:**
[IStealthereum](/src/interfaces/IStealthereum.sol/interface.IStealthereum.md)

**Author:**
mrs kzg.eth

ERC5564 compliant stealth addresses integration with an extended metadata standard


## State Variables
### _ETH_AND_SELECTOR

```solidity
bytes32 internal constant _ETH_AND_SELECTOR = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000;
```


### _TRANSFER_FROM_SELECTOR

```solidity
bytes32 internal constant _TRANSFER_FROM_SELECTOR = 0x23b872dd00000000000000000000000000000000000000000000000000000000;
```


### announcer
*chain's canonical ERC5564 announcer singleton contract*


```solidity
IERC5564Announcer public immutable announcer;
```


## Functions
### constructor


```solidity
constructor(address _announcer);
```

### stealthTransfer

stealth transfer native token and/or any number of ERC20 / ERC721 tokens directly to a stealth address on announcement to chain's ERC5564Announcer

*Caller must approve `values[i]` for each `tokens[i]` contract before invoking this function.
This function will properly encode metadata on your behalf complying with ERC5564 spec and extending it.
Any non-zero msg.value will be transferred to the stealth address too.*


```solidity
function stealthTransfer(StealthTransfer calldata transferData) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`transferData`|`StealthTransfer`|a struct containing stealth transfer params, see StealthTransfer struct|


### batchStealthTransfers

stealth transfers to multiple stealth addresses in one batched call

*Caller must approve `values[i]` for each `tokens[i]` contract (in each StealthTransfer) before invoking this function.
This function will properly encode metadata on your behalf compying with ERC5564 suggestions.*


```solidity
function batchStealthTransfers(StealthTransfer[] calldata transfersData, uint256[] calldata msgvalues)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`transfersData`|`StealthTransfer[]`|list of structs containing containing stealth transfer params, see StealthTransfer struct|
|`msgvalues`|`uint256[]`|native transfer amounts per StealthTransfer|


### parseMetadata

parse metadata to check for valid formatting and what transfers it encodes

*METADATA SPEC: the first n(56+1) bytes of metadata MUST conform to the following format (where `n` is number of native or token transfers).
First byte MUST be a view tag (if no view tag, can be any arbitrary byte but should be 0x00).
IF forwarding the native token (e.g. ETH) next 56 bytes MUST be 24 bytes of 0xee + 32 byte uint matching msg.value.
Next 56 byte chunks MAY start with 0x23b872dd (transferFrom) to be considered a token transfer.
These token transfer 56 byte chunks go 0x23b872dd + 20 byte token address + 32 byte uint of amount/tokenId to transfer.
Once the start of a 56 byte chunk does not start with 0x23b872dd, we consider this unstructured appended data.*


```solidity
function parseMetadata(bytes memory metadata)
    external
    pure
    returns (uint256 valueETH, address[] memory tokens, uint256[] memory values, uint256 extraDataLen);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadata`|`bytes`|the bytes of metadata to parse|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`valueETH`|`uint256`|amount of native ETH transferred|
|`tokens`|`address[]`|list of token transfers|
|`values`|`uint256[]`|values transferred in token transfers|
|`extraDataLen`|`uint256`|length of custom extra data appended to the standard metadata format|


### getMetadata

encode metadata from the list of transfers and any "extra" appended metadata


```solidity
function getMetadata(
    uint256 msgvalue,
    uint8 viewTag,
    address[] calldata tokens,
    uint256[] calldata values,
    bytes memory extraMetadata
) public pure returns (bytes memory metadata);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`msgvalue`|`uint256`|amount of native eth transferred|
|`viewTag`|`uint8`|view tag for the stealth transfer|
|`tokens`|`address[]`|list of token addresses (ERC20 or ERC721)|
|`values`|`uint256[]`|list of values transferred per token|
|`extraMetadata`|`bytes`|any extra data that sender wants to append to the metadata|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`metadata`|`bytes`|the encoded metadata output|


### _doTransfers


```solidity
function _doTransfers(
    uint256 msgvalue,
    address msgsender,
    address stealthAddress,
    address[] memory tokens,
    uint256[] memory values
) internal;
```

### receive


```solidity
receive() external payable;
```


# IStealthSwapHelper
[Git Source](https://github.com/kassandraoftroy/erc5564-contracts/blob/731c7df572c99212c1b4673f7aae73feff353dcf/src/interfaces/IStealthSwapHelper.sol)


## Functions
### stealthSwap

swap ETH or an ERC20 into an ERC20 before sending it to a stealth address


```solidity
function stealthSwap(StealthSwap calldata swap) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`swap`|`StealthSwap`|a struct containing swap info and stealth transfer info, see StealthSwap struct.|


### stealthSwapAndBatch

batch a stealth swap operation with a second stealth transfer

*Meant for doing a stealth swap and then clearing the rest of the used stealth address to a new "change address" all in one batched op*


```solidity
function stealthSwapAndBatch(
    StealthSwap calldata swap,
    IStealthereum.StealthTransfer calldata transferData,
    uint256 transferValueETH
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`swap`|`StealthSwap`|a struct containing swap info and stealth transfer info, see StealthSwap struct.|
|`transferData`|`IStealthereum.StealthTransfer`|a struct containing stealth transfer params, see StealthTransfer struct.|
|`transferValueETH`|`uint256`|amount of native token to send in the second stealth transfer.|


## Structs
### StealthSwap
The StealthSwap struct


```solidity
struct StealthSwap {
    uint256 schemeId;
    address stealthAddress;
    bytes ephemeralPubkey;
    uint8 viewTag;
    bytes extraMetadata;
    address inputToken;
    uint256 inputAmount;
    address outputToken;
    address swapRouter;
    bytes swapPayload;
    uint256 nativeTransfer;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`schemeId`|`uint256`|id for the stealth address cryptographic scheme (1 = secp256k1 with view tags)|
|`stealthAddress`|`address`|the stealth address to transfer to|
|`ephemeralPubkey`|`bytes`|the ephemeral pubkey used to create the stealth address (and used by recipient to find the private key)|
|`viewTag`|`uint8`|the view tag for quicker scanning|
|`extraMetadata`|`bytes`|any extra data to append to the metadata|
|`inputToken`|`address`|input token address, for swap (use 0xeeee....) for native ETH|
|`inputAmount`|`uint256`|amount of inputToken to swap|
|`outputToken`|`address`|address of output token for swap|
|`swapRouter`|`address`|target contract to call for swap action|
|`swapPayload`|`bytes`|to call on target contract for swap action|
|`nativeTransfer`|`uint256`|amount of native ETH to transfer to the stealth address receiving the output of the swap|


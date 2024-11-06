# IStealthSwapHelper
[Git Source](https://github.com/kassandraoftroy/erc5564-contracts/blob/17f8300a258dafc126636bf4c6b2cff57409473e/src/interfaces/IStealthSwapHelper.sol)


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


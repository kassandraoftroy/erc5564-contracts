# StealthSwapHelper
[Git Source](https://github.com/kassandraoftroy/erc5564-contracts/blob/56b59da890edba5d11a512ce0520cf06843bc3a8/src/StealthSwapHelper.sol)

**Inherits:**
[IStealthSwapHelper](/src/interfaces/IStealthSwapHelper.sol/interface.IStealthSwapHelper.md)

**Author:**
mrs kzg.eth

router contract for performing an ERC20 token swap before sending the result of the swap to a stealth address


## State Variables
### ETH

```solidity
address internal ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


### stealthereum

```solidity
IStealthereum public immutable stealthereum;
```


## Functions
### constructor


```solidity
constructor(address _stealthereum);
```

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


### receive


```solidity
receive() external payable;
```

## Errors
### ArrayLengthMismatch

```solidity
error ArrayLengthMismatch();
```

### NoSwapOutput

```solidity
error NoSwapOutput();
```

### WrongMsgValue

```solidity
error WrongMsgValue();
```

### SwapCallFailed

```solidity
error SwapCallFailed();
```


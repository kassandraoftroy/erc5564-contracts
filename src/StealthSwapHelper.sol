// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ITransferFrom} from "./interfaces/ITransferFrom.sol";
import {
    IStealthSwapHelper,
    IStealthereum
} from "./interfaces/IStealthSwapHelper.sol";

contract StealthSwapHelper is IStealthSwapHelper {

    error ArrayLengthMismatch();
    error NoSwapOutput();
    error WrongMsgValue();
    error SwapCallFailed();

    address internal ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IStealthereum public immutable stealthereum;

    constructor(address _stealthereum) {
        stealthereum = IStealthereum(_stealthereum);
    }

    function stealthSwap(
        StealthSwap calldata swap
    ) external payable {
        uint256 value;
        if (swap.inputToken == ETH) {
            if (swap.inputAmount + swap.nativeTransfer != msg.value) revert WrongMsgValue();
            value = swap.inputAmount;
        } else {
            ITransferFrom(swap.inputToken).transferFrom(msg.sender, address(this), swap.inputAmount);
        }

        uint256 outputTokenBefore = ITransferFrom(swap.outputToken).balanceOf(address(this));
        
        (bool success,) = swap.swapRouter.call{value: value}(swap.swapPayload);
        if (!success) revert SwapCallFailed();

        uint256 outputAmount = ITransferFrom(swap.outputToken).balanceOf(address(this)) - outputTokenBefore;
        if (outputAmount == 0) revert NoSwapOutput();

        address[] memory tokens = new address[](1);
        tokens[0] = swap.outputToken;
        uint256[] memory values = new uint256[](1);
        values[0] = outputAmount;

        stealthereum.stealthTransfer{value: swap.nativeTransfer}(
            IStealthereum.StealthTransfer({
                schemeId: swap.schemeId,
                stealthAddress: swap.stealthAddress,
                ephemeralPubkey: swap.ephemeralPubkey,
                viewTag: swap.viewTag,
                tokens: tokens,
                values: values,
                extraMetadata: swap.extraMetadata
            })
        );
    }

    function stealthSwapPlusLeftover(
        StealthSwap calldata swap,
        IStealthereum.StealthTransfer calldata transferData,
        uint256 transferValueETH
    ) external payable {
        uint256 swapValue;
        if (swap.inputToken == ETH) {
            if (swap.inputAmount + swap.nativeTransfer + transferValueETH != msg.value) revert WrongMsgValue();
            swapValue = swap.inputAmount;
        } else {
            ITransferFrom(swap.inputToken).transferFrom(msg.sender, address(this), swap.inputAmount);
        }

        uint256 outputTokenBefore = ITransferFrom(swap.outputToken).balanceOf(address(this));
        
        (bool success,) = swap.swapRouter.call{value: swapValue}(swap.swapPayload);
        if (!success) revert SwapCallFailed();

        uint256 outputAmount = ITransferFrom(swap.outputToken).balanceOf(address(this)) - outputTokenBefore;
        if (outputAmount == 0) revert NoSwapOutput();

        address[] memory tokens = new address[](1);
        tokens[0] = swap.outputToken;
        uint256[] memory values = new uint256[](1);
        values[0] = outputAmount;

        IStealthereum.StealthTransfer[] memory transfersData = new IStealthereum.StealthTransfer[](2);
        transfersData[0] = IStealthereum.StealthTransfer({
            schemeId: swap.schemeId,
            stealthAddress: swap.stealthAddress,
            ephemeralPubkey: swap.ephemeralPubkey,
            viewTag: swap.viewTag,
            tokens: tokens,
            values: values,
            extraMetadata: swap.extraMetadata
        });
        transfersData[1] = transferData;

        uint256[] memory msgvalues = new uint256[](2);
        msgvalues[0] = swap.nativeTransfer;
        msgvalues[1] = transferValueETH;

        stealthereum.batchStealthTransfers{value: swap.nativeTransfer+transferValueETH}(
            transfersData,
            msgvalues
        );
    }
}
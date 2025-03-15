// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IToken} from "./interfaces/IToken.sol";
import {
    IStealthSwapHelper,
    IStealthereum
} from "./interfaces/IStealthSwapHelper.sol";

/// @title Stealth Swap Helper
/// @author mrs kzg.eth
/// @notice router contract for performing an ERC20 token swap before sending the result of the swap to a stealth address
contract StealthSwapHelper is IStealthSwapHelper {

    error ArrayLengthMismatch();
    error NoSwapOutput();
    error WrongMsgValue();
    error SwapCallFailed();

    address constant internal ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IStealthereum public immutable stealthereum;

    constructor(address _stealthereum) {
        stealthereum = IStealthereum(_stealthereum);
    }

    /// @inheritdoc IStealthSwapHelper
    function stealthSwap(
        StealthSwap calldata swap
    ) external payable {
        uint256 value;
        if (swap.inputToken == ETH) {
            if (swap.inputAmount + swap.nativeTransfer != msg.value) revert WrongMsgValue();
            value = swap.inputAmount;
        } else {
            IToken(swap.inputToken).transferFrom(msg.sender, address(this), swap.inputAmount);
            IToken(swap.inputToken).approve(swap.swapRouter, swap.inputAmount);
        }
        
        (bool success,) = swap.swapRouter.call{value: value}(swap.swapPayload);
        if (!success) revert SwapCallFailed();

        uint256 outputAmount = IToken(swap.outputToken).balanceOf(address(this));
        if (outputAmount == 0) revert NoSwapOutput();

        address[] memory tokens = new address[](1);
        tokens[0] = swap.outputToken;
        uint256[] memory values = new uint256[](1);
        values[0] = outputAmount;

        IToken(swap.outputToken).approve(address(stealthereum), outputAmount);

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

    /// @inheritdoc IStealthSwapHelper
    function stealthSwapAndBatch(
        StealthSwap calldata swap,
        IStealthereum.StealthTransfer calldata transferData,
        uint256 transferValueETH
    ) external payable {
        uint256 swapValue;
        if (swap.inputToken == ETH) {
            if (swap.inputAmount + swap.nativeTransfer + transferValueETH != msg.value) revert WrongMsgValue();
            swapValue = swap.inputAmount;
        } else {
            IToken(swap.inputToken).transferFrom(msg.sender, address(this), swap.inputAmount);
            IToken(swap.inputToken).approve(swap.swapRouter, swap.inputAmount);
        }
        
        (bool success,) = swap.swapRouter.call{value: swapValue}(swap.swapPayload);
        if (!success) revert SwapCallFailed();

        uint256 outputAmount = IToken(swap.outputToken).balanceOf(address(this));
        if (outputAmount == 0) revert NoSwapOutput();

        for (uint256 i = 0; i < transferData.tokens.length; i++) {
            address token = transferData.tokens[i];
            uint256 v = transferData.values[i];
            IToken(token).transferFrom(msg.sender, address(this), v);
            IToken(token).approve(address(stealthereum), v);
        }

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

        IToken(swap.outputToken).approve(address(stealthereum), outputAmount);

        stealthereum.batchStealthTransfers{value: swap.nativeTransfer+transferValueETH}(
            transfersData,
            msgvalues
        );
    }

    receive() external payable {}
}
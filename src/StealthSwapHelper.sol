// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IStealthereum} from "./interfaces/IStealthereum.sol";
import {ITransferFrom} from "./interfaces/ITransferFrom.sol";

contract StealthSwapHelper {

    error WrongMsgValue();
    error SwapCallFailed();

    address internal ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IStealthereum public immutable stealthereum;

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
        bytes payload;
        uint256 nativeTransfer;
    }

    function stealthSwap(
        StealthSwap calldata swap
    ) external payable {
        if (swap.inputToken == ETH) {
            if (swap.inputAmount + swap.nativeTransfer != msg.value) revert WrongMsgValue();
        } else {
            ITransferFrom(swap.inputToken).transferFrom(msg.sender, address(this), swap.inputAmount);
        }

        uint256 outputTokenBefore = ITransferFrom(swap.outputToken).balanceOf(address(this));
        
        (bool success,) = swap.swapRouter.call(swap.payload);
        if (!success) revert SwapCallFailed();

        uint256 outputAmount = ITransferFrom(swap.outputToken).balanceOf(address(this)) - outputTokenBefore;

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
}
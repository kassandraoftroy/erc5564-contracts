// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IStealthereum} from "./IStealthereum.sol";

interface IStealthSwapHelper {
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

    function stealthSwap(
        StealthSwap calldata swap
    ) external payable;

    function stealthSwapPlusLeftover(
        StealthSwap calldata swap,
        IStealthereum.StealthTransfer calldata transferData,
        uint256 transferValueETH
    ) external payable;
    
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IStealthereum} from "./IStealthereum.sol";

interface IStealthSwapHelper {
    /// @notice The StealthSwap struct
    /// @param schemeId id for the stealth address cryptographic scheme (1 = secp256k1 with view tags)
    /// @param stealthAddress the stealth address to transfer to
    /// @param ephemeralPubkey the ephemeral pubkey used to create the stealth address (and used by recipient to find the private key)
    /// @param viewTag the view tag for quicker scanning
    /// @param extraMetadata any extra data to append to the metadata
    /// @param inputToken input token address, for swap (use 0xeeee....) for native ETH
    /// @param inputAmount amount of inputToken to swap
    /// @param outputToken address of output token for swap
    /// @param swapRouter target contract to call for swap action
    /// @param swapPayload to call on target contract for swap action
    /// @param nativeTransfer amount of native ETH to transfer to the stealth address receiving the output of the swap
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

    /// @notice swap ETH or an ERC20 into an ERC20 before sending it to a stealth address
    /// @param swap a struct containing swap info and stealth transfer info, see StealthSwap struct.
    function stealthSwap(
        StealthSwap calldata swap
    ) external payable;

    /// @notice batch a stealth swap operation with a second stealth transfer
    /// @param swap a struct containing swap info and stealth transfer info, see StealthSwap struct.
    /// @param transferData a struct containing stealth transfer params, see StealthTransfer struct.
    /// @param transferValueETH amount of native token to send in the second stealth transfer.
    /// @dev Meant for doing a stealth swap and then clearing the rest of the used stealth address to a new "change address" all in one batched op
    function stealthSwapAndBatch(
        StealthSwap calldata swap,
        IStealthereum.StealthTransfer calldata transferData,
        uint256 transferValueETH
    ) external payable;
    
}
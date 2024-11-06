// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IStealthereum} from "./IStealthereum.sol";

interface IStealthSwapHelper {
    struct StealthSwap {
        /// id for the stealth address cryptographic scheme (1 = secp256k1 with view tags)
        uint256 schemeId;
        /// the stealth address to transfer to
        address stealthAddress;
        /// the ephemeral pubkey used to create the stealth address (and used by recipient to find the private key)
        bytes ephemeralPubkey;
        /// the view tag for quicker scanning
        uint8 viewTag;
        /// any extra data to append to the metadata
        bytes extraMetadata;
        /// input token address, for swap (use 0xeeee....) for native ETH
        address inputToken;
        /// amount of inputToken to swap
        uint256 inputAmount;
        /// output token address
        address outputToken;
        /// target contract to call for swap action
        address swapRouter;
        /// payload to call on target contract for swap action
        bytes swapPayload;
        /// amount of native ETH to transfer to the stealth address receiving the output of the swap
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
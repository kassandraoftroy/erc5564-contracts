// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IStealthereum {

    error WrongMsgValue();
    error MalformattedMetadata();
    error NativeTransferFailed();
    error ArrayLengthMismatch();

    struct StealthTransfer {
        /// id for the stealth address cryptographic scheme (1 = secp256k1 with view tags)
        uint256 schemeId; 
        /// the stealth address to transfer to
        address stealthAddress;
        /// the ephemeral pubkey used to create the stealth address (and used by recipient to find the private key)
        bytes ephemeralPubkey;
        /// the view tag for quicker scanning
        uint8 viewTag;
        /// the list of tokens to transfer to the stealth address (supports both ERC20 and ERC721)
        address[] tokens;
        /// the amount (or tokenId, in the case of ERC721) to transfer per token address
        uint256[] values;
        /// any extra data to append to the metadata
        bytes extraMetadata;
    }

    /// @notice stealth transfer native token and/or any number of ERC20 / ERC721 tokens directly to a stealth address on announcement to chain's ERC5564Announcer
    /// @param transferData a struct containing stealth transfer params, see StealthTransfer struct
    /// @dev Caller must approve `values[i]` for each `tokens[i]` contract before invoking this function.
    /// This function will properly encode metadata on your behalf complying with ERC5564 spec and extending it.
    /// Any non-zero msg.value will be transferred to the stealth address too.
    function stealthTransfer(
        StealthTransfer calldata transferData
    ) external payable;

    /// @notice stealth transfers to multiple stealth addresses in one batched call
    /// @param transfersData list of structs containing containing stealth transfer params, see StealthTransfer struct
    /// @param msgvalues native transfer amounts per StealthTransfer
    /// @dev Caller must approve `values[i]` for each `tokens[i]` contract (in each StealthTransfer) before invoking this function.
    /// This function will properly encode metadata on your behalf compying with ERC5564 suggestions.
    function batchStealthTransfers(
        StealthTransfer[] calldata transfersData,
        uint256[] calldata msgvalues
    ) external payable;

    /// @notice parse metadata to check for valid formatting and what transfers it encodes
    /// @param metadata the bytes of metadata to parse
    /// @return valueETH amount of native ETH transferred
    /// @return tokens list of token transfers
    /// @return values values transferred in token transfers
    /// @return extraDataLen length of custom extra metadata (the last `extraDataLen` bytes of the submitted metadata are custom)
    /// @dev METADATA SPEC: the first n*56+1 bytes of metadata MUST conform to the following format (where `n` is number of native or token transfers).
    /// First byte MUST be a view tag (if no view tag, can be any arbitrary byte but should be 0x00).
    /// IF forwarding the native token (e.g. ETH) next 56 bytes MUST be 24 bytes of 0xee + 32 byte uint matching msg.value.
    /// Next 56 byte chunks MAY start with 0x23b872dd (transferFrom) to be considered a token transfer.
    /// These token transfer 56 byte chunks go 0x23b872dd + 20 byte token address + 32 byte uint of amount/tokenId to transfer.
    /// Once the start of a 56 byte chunk does not start with 0x23b872dd, we consider this unstructured appended data.
    function parseMetadata(
        bytes memory metadata
    ) external pure returns (uint256 valueETH, address[] memory tokens, uint256[] memory values, uint256 extraDataLen);

    /// @notice encode metadata from the list of transfers and any "extra" appended metadata
    /// @param msgvalue amount of native eth transferred
    /// @param viewTag view tag for the stealth transfer
    /// @param tokens list of token addresses (ERC20 or ERC721)
    /// @param values list of values transferred per token
    /// @param extraMetadata any extra data that sender wants to append to the metadata
    /// @return metadata the encoded metadata output
    function getMetadata(
        uint256 msgvalue,
        uint8 viewTag,
        address[] calldata tokens,
        uint256[] calldata values,
        bytes memory extraMetadata
    ) external pure returns (bytes memory metadata);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IStealthereum {

    error WrongMsgValue();
    error MalformattedMetadata();
    error NativeTransferFailed();
    error ArrayLengthMismatch();

    struct StealthTransfer {
        uint256 schemeId;
        address stealthAddress;
        bytes ephemeralPubkey;
        uint8 viewTag;
        address[] tokens;
        uint256[] values;
        bytes extraMetadata;
    }

    /// @dev transfer native token and/or any number of ERC20 / ERC721 tokens 
    /// directly to a stealth address on announcement to chain's ERC5564Announcer
    /// @param transferData a StealthTransfer struct
    /// @dev caller must approve `values[i]` for each `tokens[i]` contract before invoking this function
    /// note this function will properly encode metadata on your behalf compying with ERC5564 suggestions
    function stealthTransfer(
        StealthTransfer calldata transferData
    ) external payable;

    function batchStealthTransfers(
        StealthTransfer[] calldata transfersData,
        uint256[] calldata msgvalues
    ) external payable;

    /// @notice parse metadata to check for valid formatting and what transfers it encodes
    /// @param metadata the bytes of metadata to parse
    /// @return valueETH amount of native ETH transferred
    /// @return tokens list of token transfers
    /// @return values values transferred in token transfers
    /// @return extraMetadata custom extra metadata
    /// @dev the first n*56+1 bytes of metadata MUST conform to the following format (where `n` is number of native or token transfers)
    /// first byte MUST be a view tag (if no view tag, can be any arbitrary byte but should be 0x00)
    /// IF forwarding the native token (e.g. ETH) next 56 bytes MUST be 24 bytes of 0xee + 32 byte uint matching msg.value
    /// Next 56 byte chunks MAY start with 0x23b872dd (transferFrom) to be considered a "token transfer"
    /// these "token transfer" 56 byte chunks go 0x23b872dd + 20 byte token address + 32 byte uint of amount/tokenId to transfer
    /// Once the start of a 56 byte chunk does not start with 0x23b872dd, we consider this unstructured appended data
    function parseMetadata(
        bytes memory metadata
    ) external pure returns (uint256 valueETH, address[] memory tokens, uint256[] memory values, bytes memory extraMetadata);

    function getMetadata(
        uint256 msgvalue,
        uint8 viewTag,
        address[] calldata tokens,
        uint256[] calldata values,
        bytes memory extraMetadata
    ) external pure returns (bytes memory);
}
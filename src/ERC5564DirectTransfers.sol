// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";
import {ITransferFrom} from "./interfaces/ITransferFrom.sol";

/// @notice contract for directly transferring assets (potentially in a batch) to a stealth address
/// and announcing the stealth address data to the chain's canonical ERC5564 announcer
contract ERC5564DirectTransfers {

    error MalformattedMetadata();
    error InsufficientMsgValue();
    error NativeTransferFailed();
    error ArrayLengthMismatch();

    bytes32 internal constant _ETH_AND_SELECTOR = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000;
    bytes32 internal constant _TRANSFER_FROM_SELECTOR = 0x23b872dd00000000000000000000000000000000000000000000000000000000;

    /// @dev chain's canonical ERC5564 announcer singleton contract
    IERC5564Announcer public immutable announcer;

    /// @dev minimumTransfer has potential purpose as anti-spam (rate limiter) and/or as a way
    // to ensure each stealthAddress receiver is prefunded with gas for moving token(s) received
    // note can be set to 0 in constructor to ignore this functionality
    uint256 public immutable minimumTransfer;

    event StealthTransferDirect(
        address indexed caller,
        uint256 indexed nativeValue,
        address[] indexed tokens,
        uint256[] tokenValues
    );

    constructor(address _announcer, uint256 _minimumTransfer) {
        announcer = IERC5564Announcer(_announcer);
        minimumTransfer = _minimumTransfer;
    }

    /// @dev do a transfer of native token and any number of ERC20 / ERC721 tokens 
    /// directly to a stealth address on announcement to chain's ERC5564Announcer
    /// @param schemeId id of the stealth address scheme being used
    /// @param stealthAddress stealth address to send to
    /// @param ephemeralPubkey ephemeralPubkey associated to the stealth address
    /// @param viewTag 1 byte `view tag` of the stealth address for efficient scanning (if scheme supports)
    /// @param tokens array of ERC20/ERC721 addresses to transferFrom msg.sender to stealthAddress
    /// @param values amount of ERC20 or tokenId of ERC721 to transferFrom msg.sender to stealthAddress
    /// @dev caller must forward enough msg.value if minimumTransfer > 0
    /// caller must allso approve `values[i]` for each `tokens[i]` contract before invoking this function
    /// note this function will properly encode metadata on your behalf compying with ERC5564 suggestions
    function stealthTransfer(
        uint256 schemeId,
        address stealthAddress,
        bytes memory ephemeralPubkey,
        uint8 viewTag,
        address[] calldata tokens,
        uint256[] calldata values
    ) external payable {
        if (msg.value < minimumTransfer) revert InsufficientMsgValue();

        bytes memory metadata = getMetadata(msg.value, viewTag, tokens, values);

        _doTransfers(
            msg.value,
            msg.sender,
            schemeId,
            stealthAddress,
            ephemeralPubkey,
            metadata,
            tokens,
            values
        );
    }

    /// @dev do a transfer of native token and any number of ERC20 / ERC721 tokens 
    /// directly to a stealth address on announcement to chain's ERC5564Announcer
    /// with metadata that conforms to contract's format, optionally appended with arbitrary data
    /// @param schemeId id of the stealth address scheme being used
    /// @param stealthAddress stealth address to send to
    /// @param ephemeralPubkey ephemeralPubkey associated to the stealth address
    /// @param metadata the metadata (optionally extended) for this call
    /// @dev any token transfers correctly encoded in the metadata require approvals before invoking this function
    /// note intended use is call getMetadata() from offchain to encode valid metadata for intended transfers
    /// then append whatever bytes you like to the output and invoke this function.
    /// Learn more about encoding compliant metadats see `parseMetadata`
    function stealthTransferExtendedMetadata(
        uint256 schemeId,
        address stealthAddress,
        bytes memory ephemeralPubkey,
        bytes memory metadata
    ) external payable {
        if (msg.value < minimumTransfer) revert InsufficientMsgValue();

        (address[] memory tokens, uint256[] memory values) = parseMetadata(msg.value, metadata);

        _doTransfers(
            msg.value,
            msg.sender,
            schemeId,
            stealthAddress,
            ephemeralPubkey,
            metadata,
            tokens,
            values
        );

    }

    function _doTransfers(
        uint256 msgvalue,
        address msgsender,
        uint256 schemeId,
        address stealthAddress,
        bytes memory ephemeralPubkey,
        bytes memory metadata,
        address[] memory tokens,
        uint256[] memory values
    ) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            ITransferFrom(tokens[i]).transferFrom(msgsender, stealthAddress, values[i]);
        }

        if (msgvalue > 0) {
            bool success;
            assembly {
                success := call(gas(), stealthAddress, callvalue(), 0, 0, 0, 0)
            }
            if (!success) revert NativeTransferFailed();
        }

        emit StealthTransferDirect(msgsender, msgvalue, tokens, values);

        announcer.announce(
            schemeId, 
            stealthAddress, 
            ephemeralPubkey, 
            metadata
        );
    }

    /// @notice parse metadata to check for valid formatting and what transfers it encodes
    /// @param msgvalue the expected amount of native token transfer encoded in the metadata
    /// @param metadata the bytes of metadata to parse
    /// @return tokens and values (amounts/tokenIds) of each token to transfer (besides native token)
    /// @dev the first n*56+1 bytes of metadata MUST conform to the following format (where `n` is number of native or token transfers)
    /// first byte MUST be a view tag (if no view tag, can be any arbitrary byte but should be 0x00)
    /// IF forwarding the native token (e.g. ETH) next 56 bytes MUST be 24 bytes of 0xee + 32 byte uint matching msg.value
    /// Next 56 byte chunks MAY start with 0x23b872dd (transferFrom) to be considered a "token transfer"
    /// these "token transfer" 56 byte chunks go 0x23b872dd + 20 byte token address + 32 byte uint of amount/tokenId to transfer
    /// Once the start of a 56 byte chunk does not start with 0x23b872dd, we consider this unstructured appended data
    function parseMetadata(
        uint256 msgvalue,
        bytes memory metadata
    ) public pure returns (address[] memory tokens, uint256[] memory values) {
        uint256 len = metadata.length;
        if (len < 57) revert MalformattedMetadata();
        
        bool sendsEth = msgvalue > 0;
        if (sendsEth) {
            uint256 amountCheck;
            bytes32 prefixCheck;
            assembly {
                amountCheck := mload(add(metadata, 0x39))
                prefixCheck := shl(0x40, shr(0x40, mload(add(metadata, 0x21))))
            }
            if (msgvalue != amountCheck || _ETH_AND_SELECTOR != prefixCheck)
                revert MalformattedMetadata();
        }

        uint256 n = (len - 1)/56;
        if (n > 1 || !sendsEth) {
            assembly {
                let arrayLen := 0x00
                let startPtr := add(metadata, 0x59)
                let max := sub(n, 0x01)
                if iszero(sendsEth) {
                    max := n
                    startPtr := add(metadata, 0x21)
                }
                for {let i := 0x00} lt(i, max) {i := add(i, 0x01)} {
                    switch eq(shl(0xe0, shr(0xe0, mload(add(startPtr, mul(i, 0x38))))), _TRANSFER_FROM_SELECTOR)
                    case 0 {
                        break
                    }
                    default {
                        arrayLen := add(arrayLen, 0x01)
                    }
                }
                let tFree := mload(0x40)
                let tDataPtr := add(tFree, 0x20)
                let vFree := add(tDataPtr, mul(arrayLen, 0x20))
                let vDataPtr := add(vFree, 0x20)
                let tStartPtr := add(startPtr, 0x04)
                let vStartPtr := add(startPtr, 0x18)
                mstore(tFree, arrayLen)
                mstore(vFree, arrayLen)
                for {let j := 0x00} lt(j, arrayLen) {j := add(j, 0x01)} {
                    mstore(add(tDataPtr, mul(j, 0x20)), shr(0x60, mload(add(tStartPtr, mul(j, 0x38)))))
                    mstore(add(vDataPtr, mul(j, 0x20)), mload(add(vStartPtr, mul(j, 0x38))))
                }

                tokens := tFree
                values := vFree

                mstore(0x40, add(tFree, add(mul(arrayLen, 0x40), 0x40))) // update free memory pointer
            }
        }

        if (!sendsEth && tokens.length == 0) revert MalformattedMetadata();
    }

    /// @notice encode metadata from the view tag and intended native and token transfers 
    /// @param msgvalue the intended amount of native token transfer
    /// @param viewTag the view tag of the stealth address receiving the transfers
    /// @param tokens the intended ERC20 or ERC721 tokens to transfer
    /// @param values the intended amounts/tokenIds of tokens to transfer
    /// @return the encoded metadata
    function getMetadata(
        uint256 msgvalue,
        uint8 viewTag,
        address[] calldata tokens,
        uint256[] calldata values
    ) public pure returns (bytes memory) {
        uint256 len = tokens.length;
        if (len != values.length) revert ArrayLengthMismatch();

        bool sendsEth = msgvalue > 0;
        uint256 metadataLen = sendsEth ? 56*(len+1)+1 : 56*len+1;
        bytes memory metadata = new bytes(metadataLen);

        assembly {
            let startPtr := add(metadata, 0x21)
            let n := div(sub(metadataLen, 0x01), 0x38)
            mstore8(add(metadata, 0x20), viewTag)
            if gt(sendsEth, 0) {
                mstore(add(metadata, 0x21), _ETH_AND_SELECTOR)
                mstore(add(metadata, 0x39), msgvalue)

                startPtr := add(metadata, 0x59)
                n := sub(n, 0x01)
            }
            for {let i := 0x00} lt(i, n) {i := add(i, 0x01)} {
                let k := add(startPtr, mul(i, 0x38))
                mstore(k, _TRANSFER_FROM_SELECTOR)
                calldatacopy(0x00, add(tokens.offset, mul(i, 0x20)), 0x20)
                calldatacopy(0x20, add(values.offset, mul(i, 0x20)), 0x20)
                mstore(add(k, 0x04), shl(0x60, mload(0x00)))
                mstore(add(k, 0x18), mload(0x20))
            }
        }

        return metadata;
    }
}
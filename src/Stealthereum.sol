// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";
import {IToken} from "./interfaces/IToken.sol";
import {IStealthereum} from "./interfaces/IStealthereum.sol";

/// @notice stealth.ereum is a ERC5564 compliant stealth addresses integration with a convenient metadata standard
/// TL;DR use stealthTransfer method to privately transfer ETH / ERC20 / ERC721 directly to a stealth address and announcing it
contract Stealthereum is IStealthereum {

    bytes32 internal constant _ETH_AND_SELECTOR = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000;
    bytes32 internal constant _TRANSFER_FROM_SELECTOR = 0x23b872dd00000000000000000000000000000000000000000000000000000000;

    /// @dev chain's canonical ERC5564 announcer singleton contract
    IERC5564Announcer public immutable announcer;

    constructor(address _announcer) {
        announcer = IERC5564Announcer(_announcer);
    }

    function stealthTransfer(
        StealthTransfer calldata transferData
    ) external payable {
        bytes memory metadata = getMetadata(
            msg.value,
            transferData.viewTag,
            transferData.tokens,
            transferData.values,
            transferData.extraMetadata
        );

        _doTransfers(
            msg.value,
            msg.sender,
            transferData.stealthAddress,
            transferData.tokens,
            transferData.values
        );

        announcer.announce(
            transferData.schemeId,
            transferData.stealthAddress, 
            transferData.ephemeralPubkey, 
            metadata
        );
    }

    function batchStealthTransfers(
        StealthTransfer[] calldata transfersData,
        uint256[] calldata msgvalues
    ) external payable {
        uint256 len = transfersData.length;
        if (msgvalues.length != len) revert ArrayLengthMismatch();
        uint256 startValue = msg.value;
        uint256 endValue;
        for (uint256 i; i < len; i++) {
            bytes memory metadata = getMetadata(
                msgvalues[i],
                transfersData[i].viewTag,
                transfersData[i].tokens,
                transfersData[i].values,
                transfersData[i].extraMetadata
            );

            _doTransfers(
                msgvalues[i],
                msg.sender,
                transfersData[i].stealthAddress,
                transfersData[i].tokens,
                transfersData[i].values
            );

            announcer.announce(
                transfersData[i].schemeId,
                transfersData[i].stealthAddress, 
                transfersData[i].ephemeralPubkey, 
                metadata
            );

            endValue += msgvalues[i];
        }

        if (endValue != startValue) revert WrongMsgValue();
    }

    function parseMetadata(
        bytes memory metadata
    ) external pure returns (uint256 valueETH, address[] memory tokens, uint256[] memory values, uint256 extraDataLen) {
        uint256 len = metadata.length;
        if (len < 57) revert MalformattedMetadata();
        
        bytes32 checkSelector;
        assembly {
            checkSelector := shl(0x40, shr(0x40, mload(add(metadata, 0x21))))
        }

        bool sendsETH = checkSelector == _ETH_AND_SELECTOR;
        if (sendsETH) {
            assembly {
                valueETH := mload(add(metadata, 0x39))
            }
        }

        uint256 n = (len - 1)/56;
        uint256 arrayLen;
        if (n > 1 || !sendsETH) {
            assembly {
                let startPtr := add(metadata, 0x59)
                let max := sub(n, 0x01)
                if iszero(sendsETH) {
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

        uint256 start = sendsETH ? 57+arrayLen*56 : 1+arrayLen*56;
        extraDataLen = metadata.length - start;
    }

    function getMetadata(
        uint256 msgvalue,
        uint8 viewTag,
        address[] calldata tokens,
        uint256[] calldata values,
        bytes memory extraMetadata
    ) public pure returns (bytes memory) {
        uint256 len = tokens.length;
        if (len != values.length) revert ArrayLengthMismatch();

        bool sendsETH = msgvalue > 0;
        uint256 metadataLen = sendsETH ? 56*(len+1)+1 : 56*len+1;
        bytes memory metadata = new bytes(metadataLen);

        assembly {
            let startPtr := add(metadata, 0x21)
            let n := div(sub(metadataLen, 0x01), 0x38)
            mstore8(add(metadata, 0x20), viewTag)
            if gt(sendsETH, 0) {
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

        return bytes.concat(metadata, extraMetadata);
    }

    function _doTransfers(
        uint256 msgvalue,
        address msgsender,
        address stealthAddress,
        address[] memory tokens,
        uint256[] memory values
    ) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            IToken(tokens[i]).transferFrom(msgsender, stealthAddress, values[i]);
        }

        if (msgvalue > 0) {
            bool success;
            assembly {
                success := call(gas(), stealthAddress, callvalue(), 0, 0, 0, 0)
            }
            if (!success) revert NativeTransferFailed();
        }
    }
}
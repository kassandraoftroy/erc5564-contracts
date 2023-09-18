// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";
import {ITransferFrom} from "./interfaces/ITransferFrom.sol";
import {console} from "forge-std/console.sol";

contract ERC5564MultiTokenTransfer {

    error MalformattedMetadata();
    error InsufficientMsgValue();
    error NativeTransferFailed();
    error ArrayLengthMismatch();

    bytes32 internal constant _ETH_AND_SELECTOR = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000;
    bytes32 internal constant _TRANSFER_FROM_SELECTOR = 0x23b872dd00000000000000000000000000000000000000000000000000000000;

    IERC5564Announcer public immutable announcer;
    uint256 public immutable minimumTransfer;

    event StealthMultiTransfer(
        address indexed caller,
        uint256 msgvalue,
        address[] tokens,
        address[] values
    );

    constructor(address _announcer, uint256 _minimumTransfer) {
        announcer = IERC5564Announcer(_announcer);
        minimumTransfer = _minimumTransfer;
    }

    function stealthMultiTransfer(
        uint256 schemeId,
        address stealthAddress,
        bytes memory ephemeralPubKey,
        uint8 viewTag,
        address[] calldata tokens,
        uint256[] calldata values
    ) external payable {
        if (msg.value < minimumTransfer) revert InsufficientMsgValue();
        
        uint256 len = tokens.length;
        if (len != values.length) revert ArrayLengthMismatch();

        bool sendsEth = msg.value > 0;
        uint256 metadataLen = sendsEth ? 56*(len+1)+1 : 56*len+1;
        bytes memory metadata = new bytes(metadataLen);
        assembly {
            let startPtr := add(metadata, 0x20)
            let n := div(sub(metadataLen, 0x01), 0x38)
            if gt(sendsEth, 0) {
                mstore8(add(metadata, 0x20), viewTag)
                mstore(add(metadata, 0x21), _ETH_AND_SELECTOR)
                mstore(add(metadata, 0x39), callvalue())

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

        for (uint256 i = 0; i < len; i++) {
            ITransferFrom(tokens[i]).transferFrom(msg.sender, stealthAddress, values[i]);
        }

        bool success;
        assembly {
            success := call(gas(), stealthAddress, callvalue(), 0, 0, 0, 0)
        }
        if (!success) revert NativeTransferFailed();

        emit StealthMultiTransfer(msg.sender, msg.value, tokens, values);

        announcer.announce(
            schemeId, 
            stealthAddress, 
            ephemeralPubKey, 
            metadata
        );
    }
}
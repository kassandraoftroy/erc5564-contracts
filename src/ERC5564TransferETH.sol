// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";
import {console} from "forge-std/console.sol";

contract ERC5564TransferETH {

    error MalformattedMetadata();
    error InsufficientMsgValue();
    error NativeTransferFailed();

    bytes32 internal constant _ETH_AND_SELECTOR = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000;

    IERC5564Announcer public immutable announcer;
    uint256 public immutable minimumTransfer;

    event StealthTransferETH(address indexed caller, uint256 amount);

    constructor(address _announcer, uint256 _minimumTransfer) {
        announcer = IERC5564Announcer(_announcer);
        minimumTransfer = _minimumTransfer;
    }

    function stealthTransfer(
        uint256 schemeId,
        address stealthAddress,
        bytes memory ephemeralPubKey,
        uint8 viewTag
    ) external payable {
        if (msg.value < minimumTransfer) revert InsufficientMsgValue();

        bool success;
        bytes memory metadata = new bytes(57);
        assembly {
            mstore8(add(metadata, 0x20), viewTag)
            mstore(add(metadata, 0x21), _ETH_AND_SELECTOR)
            mstore(add(metadata, 0x39), callvalue())

            success := call(gas(), stealthAddress, callvalue(), 0, 0, 0, 0)
        }
        if (!success) revert NativeTransferFailed();

        emit StealthTransferETH(msg.sender, msg.value);

        announcer.announce(
            schemeId, 
            stealthAddress, 
            ephemeralPubKey, 
            metadata
        );
    }

    function stealthTransferCustom(
        uint256 schemeId, 
        address stealthAddress, 
        bytes memory ephemeralPubKey, 
        bytes memory metadata
    ) external payable {
        if (msg.value < minimumTransfer) revert InsufficientMsgValue();

        uint256 amountCheck;
        bytes32 prefixCheck;
        bool success;

        assembly {
            amountCheck := mload(add(metadata, 0x39))
            let ptr := mload(0x40)
            mstore(ptr, shl(0x40, shr(0x40, mload(add(metadata, 0x21)))))
            prefixCheck := mload(ptr)
            mstore(0x40, add(ptr, 0x20))

            success := call(gas(), stealthAddress, callvalue(), 0, 0, 0, 0)
        }
        if (!success) revert NativeTransferFailed();
        if (
            msg.value != amountCheck ||
            _ETH_AND_SELECTOR != prefixCheck
        ) revert MalformattedMetadata();

        emit StealthTransferETH(msg.sender, msg.value);

        announcer.announce(
            schemeId, 
            stealthAddress, 
            ephemeralPubKey, 
            metadata
        );
    }
}

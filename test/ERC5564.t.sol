// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {ERC5564TransferETH} from "../src/ERC5564TransferETH.sol";
import {ERC5564Announcer} from "../src/ERC5564Announcer.sol";
import {ERC5564MultiTransfer} from "../src/ERC5564MultiTransfer.sol";

contract CounterTest is Test {
    ERC5564TransferETH public transferrer;
    ERC5564Announcer public announcer;
    ERC5564MultiTokenTransfer public mtWithFee;
    ERC5564MultiTokenTransfer public mtNoFee;

    function setUp() public {
        announcer = new ERC5564Announcer();
        transferrer = new ERC5564TransferETH(address(announcer), 10**16);
        mtWithFee = new ERC5564MultiTokenTransfer(address(announcer), 10**15);
        mtNoFee = new ERC5564MultiTokenTransfer(address(announcer), 0);
    }

    function test_stealthTransfer() public {
        transferrer.stealthTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196
        );

        vm.expectRevert(ERC5564TransferETH.InsufficientMsgValue.selector);

        transferrer.stealthTransfer{value: 10**16-1}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196
        );
    }

    function test_stealthTransferCustom() public {
        bytes memory metadata = new bytes(57);
        assembly {
            mstore8(add(metadata, 0x20), 0xec)
            mstore(add(metadata, 0x21), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata, 0x39), 0x2386f26fc10000)
        }
        transferrer.stealthTransferCustom{value: 0x2386f26fc10000}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );

        vm.expectRevert(ERC5564TransferETH.InsufficientMsgValue.selector);
        transferrer.stealthTransferCustom{value: 0x2386f26fc0ffff}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );

        assembly {
            mstore(add(metadata, 0x39), 0x2386f26fc0ffff)
        }

        vm.expectRevert(ERC5564TransferETH.MalformattedMetadata.selector);
        transferrer.stealthTransferCustom{value: 0x2386f26fc10000}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );

        assembly {
            mstore(add(metadata, 0x21), 0x0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata, 0x39), 0x2386f26fc10000)
        }

        vm.expectRevert(ERC5564TransferETH.MalformattedMetadata.selector);
        transferrer.stealthTransferCustom{value: 0x2386f26fc10000}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );

        assembly {
            mstore(add(metadata, 0x21), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata, 0x39), 0xffffffffffffff)
        }

        transferrer.stealthTransferCustom{value: 0xffffffffffffff}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );
    }

    function test_stealthMultiTransfer() public {
        address[] memory addys = new address[](2);
        addys[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        addys[1] = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
        uint256[] memory nums = new uint256[](2);
        nums[0] = 10**18;
        nums[1] = 1;
        mtWithFee.stealthMultiTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}

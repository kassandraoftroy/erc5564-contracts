// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC5564Announcer} from "../src/ERC5564Announcer.sol";
import {ERC5564Registry} from "../src/ERC5564Registry.sol";
import {ERC5564DirectTransfers} from "../src/ERC5564DirectTransfers.sol";
import {TestERC20} from "./utils/TestERC20.sol";
import {TestERC721} from "./utils/TestERC721.sol";

// solhint-disable func-name-mixedcase

contract ERC5564Test is Test {
    ERC5564Announcer public announcer;
    ERC5564DirectTransfers public transferrer;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    TestERC721 public nft;
    ERC5564Registry public registry;

    error InvalidSignature();

    function setUp() public {
        announcer = new ERC5564Announcer();
        transferrer = new ERC5564DirectTransfers(address(announcer), 10**15);
        registry = new ERC5564Registry();

        tokenA = new TestERC20(2**200);
        tokenB = new TestERC20(2**200);
        nft = new TestERC721(12);

        tokenA.approve(address(transferrer), 2**100);
        tokenB.approve(address(transferrer), 2**100);
        nft.approve(address(transferrer), 1);
    }

    function test_stealthTransfer() public {
        address[] memory addys = new address[](3);
        addys[0] = address(tokenA);
        addys[1] = address(tokenB);
        addys[2] = address(nft);
        uint256[] memory nums = new uint256[](3);
        nums[0] = 10**18;
        nums[1] = 2**129;
        nums[2] = 1;

        tokenB.approve(address(transferrer), 2**200);
        transferrer.stealthTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );

        tokenB.approve(address(transferrer), 2**128);
        vm.expectRevert();
        transferrer.stealthTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );

        vm.expectRevert(ERC5564DirectTransfers.InsufficientMsgValue.selector);
        transferrer.stealthTransfer{value: 10**15-1}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );
        
        nums = new uint256[](2);
        nums[0] = 1000;
        nums[1] = 1 ether;
        
        vm.expectRevert(ERC5564DirectTransfers.ArrayLengthMismatch.selector);
        transferrer.stealthTransfer{value: 10**15}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );

    }

    function test_stealthTransfer1ERC20Gas() public {
        address[] memory addys = new address[](1);
        addys[0] = address(tokenA);

        uint256[] memory nums = new uint256[](1);
        nums[0] = 100 ether;

        transferrer.stealthTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );
    }

    function test_stealthTransfer1NFTGas() public {
        address[] memory addys = new address[](1);
        addys[0] = address(nft);

        uint256[] memory nums = new uint256[](1);
        nums[0] = 1;

        transferrer.stealthTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );
    }

    function test_stealthTransferOnlyETHGas() public {
        address[] memory a;
        uint256[] memory b;
        transferrer.stealthTransfer{value: 1 ether}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            a,
            b
        );
    }

    function test_stealthTransferExtendedMetadata() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        uint256[] memory values = new uint256[](2);
        values[0] = 10 ether;
        values[1] = 100 ether;
        bytes memory metadata = transferrer.getMetadata(
            1 ether,
            234,
            tokens,
            values
        );

        (address[] memory tCheck, uint256[] memory vCheck) = transferrer.parseMetadata(
            1 ether,
            metadata
        );

        assertEq(tCheck.length, vCheck.length);
        assertEq(tokens.length, tCheck.length);
        for (uint256 i=0; i<tCheck.length; i++) {
            assertEq(tokens[i], tCheck[i]);
            assertEq(values[i], vCheck[i]);
        }

        transferrer.stealthTransferExtendedMetadata{value: 1 ether}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );

        address token = address(tokenA);
        uint256 metadataLen = 150;
        bytes memory metadata2 = new bytes(metadataLen);
        assembly {
            mstore8(add(metadata2, 0x20), 0xef)
            mstore(add(metadata2, 0x21), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata2, 0x39), 0xffffffffffffffff)
            mstore(add(metadata2, 0x59), shl(0xe0, 0x23b872dd))
            mstore(add(metadata2, 0x5d), shl(0x60, token))
            mstore(add(metadata2, 0x71), 0xffffffffffffffffffff)
            mstore(add(metadata2, 0x91), 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa)
        }

        uint256 balanceBefore = tokenA.balanceOf(address(this));
        transferrer.stealthTransferExtendedMetadata{value: 0xffffffffffffffff}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata2
        );

        uint256 balanceAfter = tokenA.balanceOf(address(this));
        assertEq(balanceBefore-balanceAfter, 0xffffffffffffffffffff);

        vm.expectRevert(ERC5564DirectTransfers.MalformattedMetadata.selector);
        transferrer.stealthTransferExtendedMetadata{value: 0xfffffffffffffffd}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata2
        );

        vm.expectRevert(ERC5564DirectTransfers.MalformattedMetadata.selector);
        transferrer.stealthTransferExtendedMetadata{value: 0xffffffffffffffff}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            new bytes(56)
        );

        vm.expectRevert(ERC5564DirectTransfers.InsufficientMsgValue.selector);
        transferrer.stealthTransferExtendedMetadata{value: 10**15-1}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata2
        );
    }

    function test_stealthTransferExtendedMetadataOnlyETHGas() public {
        bytes memory metadata = new bytes(100);
        assembly {
            mstore8(add(metadata, 0x20), 0xef)
            mstore(add(metadata, 0x21), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata, 0x39), 0xffffffffffffffff)
            mstore(add(metadata, 0x59), 0xaaaaaaaaaaaaaaaaaaaaaaaaa)
        }
        transferrer.stealthTransferExtendedMetadata{value: 0xffffffffffffffff}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata
        );
    }

    function test_stealthTransferExtendedMetadata1ERC20Gas() public {
        address token = address(tokenA);
        bytes memory metadata2 = new bytes(140);
        assembly {
            mstore8(add(metadata2, 0x20), 0xef)
            mstore(add(metadata2, 0x21), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata2, 0x39), 0xffffffffffffffff)
            mstore(add(metadata2, 0x59), shl(0xe0, 0x23b872dd))
            mstore(add(metadata2, 0x5d), shl(0x60, token))
            mstore(add(metadata2, 0x71), 0xffffffffffffffffffff)
            mstore(add(metadata2, 0x91), 0xaaaaaaaaaaaaaa)
        }

        transferrer.stealthTransferExtendedMetadata{value: 0xffffffffffffffff}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata2
        );
    }

    function test_stealthTransferExtendedMetadata1NFTGas() public {
        address token = address(nft);
        bytes memory metadata2 = new bytes(140);
        assembly {
            mstore8(add(metadata2, 0x20), 0xef)
            mstore(add(metadata2, 0x21), 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000)
            mstore(add(metadata2, 0x39), 0xffffffffffffffff)
            mstore(add(metadata2, 0x59), shl(0xe0, 0x23b872dd))
            mstore(add(metadata2, 0x5d), shl(0x60, token))
            mstore(add(metadata2, 0x71), 0x01)
            mstore(add(metadata2, 0x91), 0xaaaaaaaaaaaaaa)
        }

        transferrer.stealthTransferExtendedMetadata{value: 0xffffffffffffffff}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            metadata2
        );
    }

    function test_noMinTransfer() public {
        ERC5564DirectTransfers noRateLimit = new ERC5564DirectTransfers(address(announcer), 0);
        address[] memory x;
        uint256[] memory y;
        noRateLimit.stealthTransfer{value: 1 ether}(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            119,
            x,
            y
        );

        x = new address[](1);
        x[0] = 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1;
        y = new uint256[](1);
        y[0] = 1 ether;

        bytes memory metadata = noRateLimit.getMetadata(
            0,
            119,
            x,
            y
        );

        assertEq(metadata.length, 57);
        assertEq(metadata, bytes(hex"7723b872ddBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB10000000000000000000000000000000000000000000000000de0b6b3a7640000"));

        (address[] memory tokens, uint256[] memory amounts) = noRateLimit.parseMetadata(
            0,
            metadata
        );

        assertEq(tokens.length, 1);
        assertEq(amounts.length, 1);
        assertEq(tokens[0], 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1);
        assertEq(amounts[0], 1 ether);

        tokenA.approve(address(noRateLimit), 10**25);
        x[0] = address(tokenA);
        uint256 balanceBefore = tokenA.balanceOf(address(this));
        noRateLimit.stealthTransfer(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            119,
            x,
            y
        );
        uint256 balanceAfter = tokenA.balanceOf(address(this));

        assertEq(balanceBefore-balanceAfter, 1 ether);
    }

    function test_registry_basic() public {
        bytes memory pk = bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de");
        registry.registerKeys(0, pk);

        bytes memory result = registry.stealthMetaAddressOf(address(this), 0);
        assertEq(result, pk);
    }

    function test_registry_on_behalf() public {
        bytes memory pk = bytes(hex"03dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de");
        uint256 priv = 0xabcdef123456789;
        bytes32 datahash = keccak256(abi.encode(
            keccak256("Registration(address registrant,uint256 scheme,bytes stealthMetaAddress,uint256 nonce)"),
            vm.addr(priv),
            0,
            pk,
            1
        ));
        bytes32 msghash = keccak256(
            abi.encodePacked("\x19\x01", registry.DOMAIN_SEPARATOR(), datahash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(priv, msghash);
        bytes memory sig = abi.encodePacked(r, s, v);
        {
            registry.registerKeysOnBehalf(vm.addr(priv), 0, sig, pk);

            bytes memory result = registry.stealthMetaAddressOf(vm.addr(priv), 0);
            assertEq(result, pk);

            uint256 nonceCheck = registry.nonceOf(vm.addr(priv));
            assertEq(nonceCheck, 1);
        }

        bytes memory pk2 = bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de");
        datahash = keccak256(abi.encode(
            keccak256("Registration(address registrant,uint256 scheme,bytes stealthMetaAddress,uint256 nonce)"),
            vm.addr(priv),
            0,
            pk2,
            2
        ));
        msghash = keccak256(
            abi.encodePacked("\x19\x01", registry.DOMAIN_SEPARATOR(), datahash)
        );
        (v, r, s) = vm.sign(priv, msghash);
        bytes memory sig2 = abi.encodePacked(r, s, v);

        datahash = keccak256(abi.encode(
            keccak256("Registration(address registrant,uint256 scheme,bytes stealthMetaAddress,uint256 nonce)"),
            vm.addr(priv),
            0,
            pk,
            3
        ));
        msghash = keccak256(
            abi.encodePacked("\x19\x01", registry.DOMAIN_SEPARATOR(), datahash)
        );
        (v, r, s) = vm.sign(priv, msghash);
        bytes memory sig3 = abi.encodePacked(r, s, v);

        vm.expectRevert(InvalidSignature.selector);
        registry.registerKeysOnBehalf(vm.addr(priv), 0, sig, pk);

        vm.expectRevert(InvalidSignature.selector);
        registry.registerKeysOnBehalf(vm.addr(priv), 0, sig3, pk);

        registry.registerKeysOnBehalf(vm.addr(priv), 0, sig2, pk2);

        assertEq(registry.stealthMetaAddressOf(vm.addr(priv), 0), pk2);

        assertEq(registry.nonceOf(vm.addr(priv)), 2);
    }
}

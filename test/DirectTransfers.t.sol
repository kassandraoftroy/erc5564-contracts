// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC5564DirectTransfers} from "../src/ERC5564DirectTransfers.sol";
import {IERC20} from "./utils/IERC20.sol";
import {IERC721} from "./utils/IERC721.sol";
import {TestWrapper} from "./TestWrapper.sol";

// solhint-disable func-name-mixedcase
contract ERC5564DirectTransfersTest is TestWrapper {
    address public announcer = 0x55649E01B5Df198D18D95b5cc5051630cfD45564;
    address public tokenA = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public tokenB = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public nft = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    // address public registry = 0x6538E6bf4B0eBd30A8Ea093027Ac2422ce5d6538;
    address public miladyHolder = 0x398d282487b44b6e53Ce0AebcA3CB60C3B6325E9;
    address public wethHolder = 0x741AA7CFB2c7bF2A1E7D4dA2e3Df6a56cA4131F3;
    address public daiHolder = 0xD1668fB5F690C59Ab4B0CAbAd0f8C1617895052B;
    ERC5564DirectTransfers public transferrer;

    error InvalidSignature();

    function setUp() public {
        transferrer = new ERC5564DirectTransfers(address(announcer), 10**15);
        
        vm.prank(miladyHolder);
        IERC721(nft).transferFrom(miladyHolder, address(this), 4617);
        
        vm.prank(wethHolder);
        IERC20(tokenA).transfer(address(this), 10000 ether);
        
        vm.prank(daiHolder);
        IERC20(tokenB).transfer(address(this), 10000 ether);

        IERC20(tokenA).approve(address(transferrer), 2**100);
        IERC20(tokenB).approve(address(transferrer), 2**100);
        IERC721(nft).approve(address(transferrer), 4617);
    }

    function test_stealthTransfer() public {
        address[] memory addys = new address[](3);
        addys[0] = tokenA;
        addys[1] = tokenB;
        addys[2] = nft;
        uint256[] memory nums = new uint256[](3);
        nums[0] = 10**18;
        nums[1] = 10**21;
        nums[2] = 4617;

        uint256 balanceABefore = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceBBefore = IERC20(tokenB).balanceOf(address(this));
        assertEq(IERC721(nft).ownerOf(4617), address(this));
        transferrer.stealthTransfer{value: 10**16}(
            0,
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            196,
            addys,
            nums
        );

        assertEq(balanceABefore - 10**18, IERC20(tokenA).balanceOf(address(this)));
        assertEq(balanceBBefore - 10**21, IERC20(tokenB).balanceOf(address(this)));
        assertEq(IERC721(nft).ownerOf(4617), 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1);

        IERC20(tokenB).approve(address(transferrer), 10**20);
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

    function test_stealthTransferOnlyETH() public {
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

        IERC20(tokenA).approve(address(noRateLimit), 10**25);
        x[0] = address(tokenA);
        uint256 balanceBefore = IERC20(tokenA).balanceOf(address(this));
        noRateLimit.stealthTransfer(
            0, 
            0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
            bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
            119,
            x,
            y
        );
        uint256 balanceAfter = IERC20(tokenA).balanceOf(address(this));

        assertEq(balanceBefore-balanceAfter, 1 ether);
    }
}

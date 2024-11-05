// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Stealthereum} from "../src/Stealthereum.sol";
import {IStealthereum} from "../src/interfaces/IStealthereum.sol";
import {IERC20} from "./utils/IERC20.sol";
import {IERC721} from "./utils/IERC721.sol";
import {TestWrapper} from "./TestWrapper.sol";

// solhint-disable func-name-mixedcase
contract StealthereumTest is TestWrapper {
    address public announcer = 0x55649E01B5Df198D18D95b5cc5051630cfD45564;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public nft = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    // address public registry = 0x6538E6bf4B0eBd30A8Ea093027Ac2422ce5d6538;
    address public miladyHolder = 0x398d282487b44b6e53Ce0AebcA3CB60C3B6325E9;
    address public wethHolder = 0x741AA7CFB2c7bF2A1E7D4dA2e3Df6a56cA4131F3;
    address public daiHolder = 0xD1668fB5F690C59Ab4B0CAbAd0f8C1617895052B;
    Stealthereum public transferrer;

    error InvalidSignature();

    function setUp() public {
        transferrer = new Stealthereum(address(announcer));
        
        vm.prank(miladyHolder);
        IERC721(nft).transferFrom(miladyHolder, address(this), 4617);
        
        vm.prank(wethHolder);
        IERC20(weth).transfer(address(this), 10000 ether);
        
        vm.prank(daiHolder);
        IERC20(dai).transfer(address(this), 10000 ether);

        IERC20(weth).approve(address(transferrer), 2**100);
        IERC20(dai).approve(address(transferrer), 2**100);
        IERC721(nft).approve(address(transferrer), 4617);
    }

    function test_stealthTransfer() public {
        address[] memory addys = new address[](3);
        addys[0] = weth;
        addys[1] = dai;
        addys[2] = nft;
        uint256[] memory nums = new uint256[](3);
        nums[0] = 10**18;
        nums[1] = 10**21;
        nums[2] = 4617;

        uint256 balanceABefore = IERC20(weth).balanceOf(address(this));
        uint256 balanceBBefore = IERC20(dai).balanceOf(address(this));
        assertEq(IERC721(nft).ownerOf(4617), address(this));
        transferrer.stealthTransfer{value: 10**16}(
            IStealthereum.StealthTransfer({
                schemeId: 1,
                stealthAddress: 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
                ephemeralPubkey: bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
                viewTag: 196,
                tokens: addys,
                values: nums,
                extraMetadata: bytes("")
            })
        );

        assertEq(balanceABefore - 10**18, IERC20(weth).balanceOf(address(this)));
        assertEq(balanceBBefore - 10**21, IERC20(dai).balanceOf(address(this)));
        assertEq(IERC721(nft).ownerOf(4617), 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1);

        IERC20(dai).approve(address(transferrer), 10**20);
        vm.expectRevert();
        transferrer.stealthTransfer{value: 10**16}(
            IStealthereum.StealthTransfer({
                schemeId: 1,
                stealthAddress: 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
                ephemeralPubkey: bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
                viewTag: 196,
                tokens: addys,
                values: nums,
                extraMetadata: bytes("")
            })
        );
        
        nums = new uint256[](2);
        nums[0] = 1000;
        nums[1] = 1 ether;
        
        vm.expectRevert(IStealthereum.ArrayLengthMismatch.selector);
        transferrer.stealthTransfer{value: 10**15}(
            IStealthereum.StealthTransfer({
                schemeId: 1,
                stealthAddress: 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
                ephemeralPubkey: bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
                viewTag: 196,
                tokens: addys,
                values: nums,
                extraMetadata: bytes("")
            })
        );

    }

    function test_stealthTransferOnlyETH() public {
        address[] memory a;
        uint256[] memory b;
        transferrer.stealthTransfer{value: 1 ether}(
            IStealthereum.StealthTransfer({
                schemeId: 1,
                stealthAddress: 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1,
                ephemeralPubkey: bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
                viewTag: 196,
                tokens: a,
                values: b,
                extraMetadata: bytes("")
            })
        );
    }

    function test_stealthTransferExtendedMetadata() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(weth);
        tokens[1] = address(dai);
        uint256[] memory values = new uint256[](2);
        values[0] = 10 ether;
        values[1] = 100 ether;
        bytes memory extraCheck = bytes("IAMEXTRADATA");
        bytes memory metadata = transferrer.getMetadata(
            1 ether,
            234,
            tokens,
            values,
            extraCheck
        );

        (uint256 vETHCheck, address[] memory tCheck, uint256[] memory vCheck, uint256 extraLength) = transferrer.parseMetadata(
            metadata
        );

        assertEq(vETHCheck, 1 ether);
        assertEq(tCheck.length, vCheck.length);
        assertEq(tokens.length, tCheck.length);
        for (uint256 i=0; i<tCheck.length; i++) {
            assertEq(tokens[i], tCheck[i]);
            assertEq(values[i], vCheck[i]);
        }

        assertEq(extraCheck.length, extraLength);

    }
}

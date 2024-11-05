// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {
    IStealthereum,
    Stealthereum
} from "../src/Stealthereum.sol";
import {
    IStealthSwapHelper,
    StealthSwapHelper
} from "../src/StealthSwapHelper.sol";
import {IERC20} from "./utils/IERC20.sol";
import {IERC721} from "./utils/IERC721.sol";
import {IRouter} from "./utils/IRouter.sol";
import {TestWrapper} from "./TestWrapper.sol";

// solhint-disable func-name-mixedcase
contract StealthSwapTest is TestWrapper {
    address public announcer = 0x55649E01B5Df198D18D95b5cc5051630cfD45564;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public nft = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    // address public registry = 0x6538E6bf4B0eBd30A8Ea093027Ac2422ce5d6538;
    address public miladyHolder = 0x398d282487b44b6e53Ce0AebcA3CB60C3B6325E9;
    address public wethHolder = 0x741AA7CFB2c7bF2A1E7D4dA2e3Df6a56cA4131F3;
    address public daiHolder = 0xD1668fB5F690C59Ab4B0CAbAd0f8C1617895052B;
    address public uniV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    Stealthereum public transferrer;
    StealthSwapHelper public helper;

    error InvalidSignature();

    function setUp() public {
        transferrer = new Stealthereum(address(announcer));
        helper = new StealthSwapHelper(address(transferrer));
        
        vm.prank(miladyHolder);
        IERC721(nft).transferFrom(miladyHolder, address(this), 4617);
        
        vm.prank(wethHolder);
        IERC20(weth).transfer(address(this), 10000 ether);
        
        vm.prank(daiHolder);
        IERC20(dai).transfer(address(this), 10000 ether);
    }

    function test_stealthSwap() public {
        address firstReceiver = 0xBbC640bD5FcbCBe3bb7D6570A2bd94E2d7441BB1;
        address[] memory addys = new address[](1);
        addys[0] = nft;
        uint256[] memory nums = new uint256[](1);
        nums[0] = 4617;

        assertEq(IERC721(nft).ownerOf(4617), address(this));
        
        IERC721(nft).approve(address(transferrer), 4617);

        transferrer.stealthTransfer{value: 10**19}(
            IStealthereum.StealthTransfer({
                schemeId: 1,
                stealthAddress: firstReceiver,
                ephemeralPubkey: bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
                viewTag: 196,
                tokens: addys,
                values: nums,
                extraMetadata: bytes("")
            })
        );

        assertEq(IERC721(nft).ownerOf(4617), firstReceiver);
        assertEq(firstReceiver.balance, 10**19);

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = dai;

        address secondReceiver = 0x454f193FD7AD2a395Bb54711DF5Ec4662A8E34C1;
        bytes memory swapPayload = abi.encodeWithSelector(IRouter.swapExactETHForTokens.selector, 0, path, address(helper), 999999999999);

        helper.stealthSwap{value: 0.91 ether}(
            IStealthSwapHelper.StealthSwap({
                schemeId: 1,
                stealthAddress: secondReceiver,
                ephemeralPubkey: bytes(hex"02dc2fd7137fe03c1c26a943e07e525518b32ee1818ccd2b6bbae3218b746a06de"),
                viewTag: 196,
                extraMetadata: bytes(""),
                inputToken: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                inputAmount: 0.9 ether,
                outputToken: dai,
                swapRouter: uniV2Router,
                swapPayload: swapPayload,
                nativeTransfer: 0.01 ether
            })
        );
    }
}

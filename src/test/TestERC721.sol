// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {
    constructor(uint256 n) ERC721("NFT", "N") {
        for (uint256 i = 1; i < n+1; i++) {
            _mint(msg.sender, i);
        }
    }
}
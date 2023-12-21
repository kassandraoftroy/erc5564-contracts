// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC721} from "lib/solady/src/tokens/ERC721.sol";

contract TestERC721 is ERC721 {
    constructor(uint256 n) {
        for (uint256 i = 1; i < n+1; i++) {
            _mint(msg.sender, i);
        }
    }

    function name() public pure override returns (string memory) {
        return "NFT";
    }

    function symbol() public pure override returns (string memory) {
        return "N";
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        return string(abi.encode(id));
    }
}
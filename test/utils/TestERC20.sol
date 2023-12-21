// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(uint256 supply) {
        _mint(msg.sender, supply);
    }
    
    function name() public pure override returns (string memory) {
        return "TOKEN";
    }

    function symbol() public pure override returns (string memory) {
        return "T";
    }

}
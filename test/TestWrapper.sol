// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract TestWrapper is Test {
    constructor() {
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"),
            vm.envUint("ETH_BLOCK_NUMBER")
        );
    }

    function _reset(
        string memory url_,
        uint256 blockNumber
    ) internal {
        vm.createSelectFork(url_, blockNumber);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITransferFrom {
    function transferFrom(address, address, uint256) external;

    function balanceOf(address) external returns (uint256);
}
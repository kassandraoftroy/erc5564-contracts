// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITransferFrom {
    function transferFrom(address, address, uint256) external;
}
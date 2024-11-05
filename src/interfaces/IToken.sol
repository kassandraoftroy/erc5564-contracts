// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IToken {
    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function approve(address, uint256) external returns (bool);
}
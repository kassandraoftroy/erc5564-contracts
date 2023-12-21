// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}
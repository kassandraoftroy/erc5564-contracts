// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";

/// @notice Contract for announcing when something is sent to a stealth address.
contract ERC5564Announcer is IERC5564Announcer {
  function announce (
    uint256 schemeId, 
    address stealthAddress, 
    bytes memory ephemeralPubKey, 
    bytes memory metadata
  )
    external
  {
    emit Announcement(schemeId, stealthAddress, msg.sender, ephemeralPubKey, metadata);
  }
}
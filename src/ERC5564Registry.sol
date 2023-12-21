// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// NOTE adaptation of code found here https://eips.ethereum.org/EIPS/eip-6538

import {IERC1271} from "./interfaces/IERC1271.sol";
import {IENS} from "./interfaces/IENS.sol";
import {IENSResolver} from "./interfaces/IENSResolver.sol";

/// @notice Registry to map an address or other identifier to its stealth meta-address.
contract ERC5564Registry {

    error InvalidSignature();
    error ZeroAddress();

    bytes4 constant internal _MAGICVALUE = 0x1626ba7e;

    IENS immutable public ens;

    /// @dev Emitted when a registrant updates their stealth meta-address.
    event StealthMetaAddressSet(
        bytes32 indexed registrant, uint256 indexed scheme, bytes stealthMetaAddress
    );

    /// @notice Maps a registrant's identifier to the scheme to the stealth meta-address.
    /// @dev Registrant may be a 160 bit address, or a 256 bit node hash of an ENS name.
    /// @dev Scheme is an integer identifier for the stealth address scheme.
    /// @dev MUST return zero if a registrant has not registered keys for the given inputs.
    mapping(bytes32 => mapping(uint256 => bytes)) public stealthMetaAddressOf;

    constructor(address ens_) {
        ens = IENS(ens_);
    }

    /// @notice Sets the caller's stealth meta-address for the given stealth address scheme.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param stealthMetaAddress The stealth meta-address to register.
    function registerKeys(uint256 scheme, bytes memory stealthMetaAddress) external {
        stealthMetaAddressOf[bytes32(uint256(uint160(msg.sender)))][scheme] = stealthMetaAddress;
    }

    /// @notice Sets the `registrant`s stealth meta-address for the given scheme.
    /// @param registrant Recipient identifier, in this case an ethereum address.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param signature A signature from the `registrant` authorizing the registration.
    /// @param stealthMetaAddress The stealth meta-address to register.
    /// @dev MUST support both EOA signatures and EIP-1271 signatures.
    /// @dev MUST revert if the signature is invalid.
    function registerKeysOnBehalf(
        address registrant,
        uint256 scheme,
        bytes memory signature,
        bytes memory stealthMetaAddress
    ) external {
        bytes32 msghash = keccak256(abi.encode(stealthMetaAddress, scheme));

        _verifySignature(registrant, msghash, signature);
        
        stealthMetaAddressOf[bytes32(uint256(uint160(registrant)))][scheme] = stealthMetaAddress;
    }

    /// @notice Sets the `registrant`s stealth meta-address for the given scheme.
    /// @param registrant Recipient identifier, in this case an ENS name's 256 bit node hash.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param signature A signature from the `registrant` authorizing the registration.
    /// @param stealthMetaAddress The stealth meta-address to register.
    /// @dev MUST support both EOA signatures and EIP-1271 signatures.
    /// @dev MUST revert if the signature is invalid.
    function registerKeysOnBehalfENS(
        bytes32 registrant,
        uint256 scheme,
        bytes memory signature,
        bytes memory stealthMetaAddress
    ) external {
        address addr = IENSResolver(ens.resolver(registrant)).addr(registrant);
        bytes32 msghash = keccak256(abi.encode(registrant, stealthMetaAddress, scheme));

        _verifySignature(addr, msghash, signature);

        stealthMetaAddressOf[registrant][scheme] = stealthMetaAddress;
    }

    function _verifySignature(
        address registrant,
        bytes32 msghash,
        bytes memory signature
    ) internal view {
        if (registrant == address(0)) revert ZeroAddress();
        if (registrant.code.length > 0) {
            if (IERC1271(registrant).isValidSignature(msghash, signature) != _MAGICVALUE) revert InvalidSignature();
        } else {
            if (signature.length != 65) revert InvalidSignature();

            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }

            if (ecrecover(msghash, v, r, s) != registrant) revert InvalidSignature();
        }
    }
}
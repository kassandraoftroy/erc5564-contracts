// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// NOTE adaptation of code found here https://eips.ethereum.org/EIPS/eip-6538
/// only a minimal, partial implementation of ERC6538

import {IERC1271} from "./interfaces/IERC1271.sol";

/// @notice Registry to map an address or other identifier to its stealth meta-address.
contract ERC5564Registry {

    error InvalidSignature();

    bytes4 constant internal _MAGICVALUE = 0x1626ba7e;

    /// @dev Emitted when a registrant updates their stealth meta-address.
    event StealthMetaAddressSet(
        bytes indexed registrant, uint256 indexed scheme, bytes stealthMetaAddress
    );

    /// @notice Maps a registrant's identifier to the scheme to the stealth meta-address.
    /// @dev Registrant may be a 160 bit address or other recipient identifier, such as an ENS name.
    /// @dev Scheme is an integer identifier for the stealth address scheme.
    /// @dev MUST return zero if a registrant has not registered keys for the given inputs.
    mapping(bytes => mapping(uint256 => bytes)) public stealthMetaAddressOf;

    /// @notice Sets the caller's stealth meta-address for the given stealth address scheme.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param stealthMetaAddress The stealth meta-address to register.
    function registerKeys(uint256 scheme, bytes memory stealthMetaAddress) external {
        stealthMetaAddressOf[abi.encode(msg.sender)][scheme] = stealthMetaAddress;
    }

    /// @notice Sets the `registrant`s stealth meta-address for the given scheme.
    /// @param registrant Recipient identifier, such as an ENS name.
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
        bytes32 hash_ = keccak256(abi.encode(stealthMetaAddress, scheme));

        if (registrant.code.length > 0) {
            if (IERC1271(registrant).isValidSignature(hash_, signature) != _MAGICVALUE) revert InvalidSignature();
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

            if (ecrecover(hash_, v, r, s) != registrant) revert InvalidSignature();
        }

        stealthMetaAddressOf[abi.encode(msg.sender)][scheme] = stealthMetaAddress;
    }

    /// NOTE function below is unimplemented, making this an incomplete ERC6538 implementation
    /// imho this may not be very easy/simple to do in a generic way, EIP authors should revisit

    /// @notice Sets the `registrant`s stealth meta-address for the given scheme.
    /// @param registrant Recipient identifier, such as an ENS name.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param signature A signature from the `registrant` authorizing the registration.
    /// @param stealthMetaAddress The stealth meta-address to register.
    /// @dev MUST support both EOA signatures and EIP-1271 signatures.
    /// @dev MUST revert if the signature is invalid.
    // function registerKeysOnBehalf(
    //     bytes memory registrant,
    //     uint256 scheme,
    //     bytes memory signature,
    //     bytes memory stealthMetaAddress
    // ) external {
    //     // TODO How to best generically support any registrant identifier / name
    //     // system without e.g. hardcoding support just for ENS?
    // }

    /// @notice helper in case view caller to lazy to encode registrant address to bytes
    /// @param registrant Address to get stealth meta address of
    /// @param scheme An integer identifier for the stealth address scheme
    /// @return stealth meta address of registrant
    function getStealthMetaAddressOf(
        address registrant,
        uint256 scheme
    ) external view returns (bytes memory) {
        return stealthMetaAddressOf[abi.encode(registrant)][scheme];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// NOTE adaptation of code found here https://eips.ethereum.org/EIPS/eip-6538

import {IERC1271} from "./interfaces/IERC1271.sol";
import {EIP712} from "./EIP712.sol";

/// @notice Registry to map an address or other identifier to its stealth meta-address.
contract ERC5564Registry is EIP712 {

    error InvalidSignature();
    error ZeroAddress();

    bytes4 constant internal _MAGICVALUE = 0x1626ba7e;

    /// @dev to sign typed data correctly offchain (for registerOnBehalf method)
    /// @dev sign a struct in this exact form with eth_signTypedData:
    /// struct Registration {
    ///     address registrant;
    ///     uint256 scheme;
    ///     bytes stealthMetaAddress;
    ///     uint256 nonce;
    /// }
    /// @dev where nonce signed MUST be nonceOf[registrant]++ (the current value of registrant's nonce incremented by 1)
    bytes32 constant internal _REGISTRATION_TYPEHASH = keccak256("Registration(address registrant,uint256 scheme,bytes stealthMetaAddress,uint256 nonce)");

    /// @dev Emitted when a registrant updates their stealth meta-address.
    event StealthMetaAddressSet(
        address indexed registrant, uint256 indexed scheme, bytes stealthMetaAddress
    );

    /// @notice Maps a registrant to the scheme to the stealth meta-address.
    /// @dev Registrant MUST be a valid 160 bit address.
    /// @dev Scheme is an integer identifier for the stealth address scheme.
    /// @dev MUST return zero if a registrant has not registered keys for the given inputs.
    mapping(address => mapping(uint256 => bytes)) public stealthMetaAddressOf;

    /// @notice tracks registrant nonce for replay attacks of registerOnBehalfOf
    mapping(address => uint256) public nonceOf;

    /// @notice Sets the caller's stealth meta-address for the given stealth address scheme.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param stealthMetaAddress The stealth meta-address to register.
    function registerKeys(uint256 scheme, bytes memory stealthMetaAddress) external {
        stealthMetaAddressOf[msg.sender][scheme] = stealthMetaAddress;
    }

    /// @notice Sets the `registrant`s stealth meta-address for the given scheme.
    /// @param registrant Registrant's address.
    /// @param scheme An integer identifier for the stealth address scheme.
    /// @param signature A signature from the `registrant` addresss authorizing the registration.
    /// @param stealthMetaAddress The stealth meta-address to register.
    /// @dev MUST support both EOA signatures and EIP-1271 signatures.
    /// @dev MUST revert if the signature is invalid.
    function registerKeysOnBehalf(
        address registrant,
        uint256 scheme,
        bytes memory signature,
        bytes memory stealthMetaAddress
    ) external {
        if (registrant == address(0)) revert ZeroAddress();

        bytes32 msghash = _hashTypedData(keccak256(abi.encode(_REGISTRATION_TYPEHASH, registrant, scheme, stealthMetaAddress, ++nonceOf[registrant])));

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
        
        stealthMetaAddressOf[registrant][scheme] = stealthMetaAddress;
    }
}
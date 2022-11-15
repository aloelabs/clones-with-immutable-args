// SPDX-License-Identifier: BSD
pragma solidity ^0.8.15;

import {Create2} from "./Create2.sol";

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth, Saw-mon & Natalie, wminshew
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    // abi.encodeWithSignature("CreateFail()")
    uint256 constant CreateFail_error_signature = 0xebfef18800000000000000000000000000000000000000000000000000000000;

    // abi.encodeWithSignature("IdentityPrecompileFailure()")
    uint256 constant IdentityPrecompileFailure_error_signature =
        0x3a008ffa00000000000000000000000000000000000000000000000000000000;

    uint256 constant custom_error_sig_ptr = 0x0;

    uint256 constant custom_error_length = 0x4;

    uint256 private constant FREE_MEMORY_POINTER_SLOT = 0x40;
    uint256 private constant BOOTSTRAP_LENGTH = 0x3f; // 63 (43 instructions + 20 for implementation address)
    uint256 private constant ONE_WORD = 0x20;

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        assembly ("memory-safe") {
            instance := create(0, creationPtr, creationSize)

            // if the create failed, the instance address won't be set
            if iszero(instance) {
                mstore(custom_error_sig_ptr, CreateFail_error_signature)
                revert(custom_error_sig_ptr, custom_error_length)
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        assembly ("memory-safe") {
            instance := create2(0, creationPtr, creationSize, salt)

            // if the create failed, the instance address won't be set
            if iszero(instance) {
                mstore(custom_error_sig_ptr, CreateFail_error_signature)
                revert(custom_error_sig_ptr, custom_error_length)
            }
        }
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer,
        bytes memory data
    ) internal pure returns (address predicted) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        bytes32 bytecodeHash;
        assembly ("memory-safe") {
            bytecodeHash := keccak256(creationPtr, creationSize)
        }

        predicted = Create2.computeAddress(salt, bytecodeHash, deployer);
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal view returns (address predicted) {
        predicted = predictDeterministicAddress(implementation, salt, address(this), data);
    }

    /// @notice Computes the creation code for a clone with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ptr The ptr to the clone's bytecode
    /// @return creationSize The size of the clone to be created
    function _getCreationCode(
        address implementation,
        bytes memory data
    ) private pure returns (uint256 ptr, uint256 creationSize) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        assembly {
            // TODO mark whether this assembly is memory safe for new IR optimizer
            let extraLength := add(mload(data), 2) // +2 bytes for telling how much data there is appended to the call
            creationSize := add(extraLength, BOOTSTRAP_LENGTH)
            let runSize := sub(creationSize, 0x0a)

            // free memory pointer
            ptr := mload(FREE_MEMORY_POINTER_SLOT)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (10 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // 61 runtime  | PUSH2 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 offset   | PUSH1 offset (o)      | o r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 o r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0 - runSize): runtime code
            // f3          | RETURN                |                         | [0 - runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes + extraLength)
            // -------------------------------------------------------------------------------------------------------------

            // --- copy calldata to memmory ---
            // 36          | CALLDATASIZE          | cds                     | –
            // 3d          | RETURNDATASIZE        | 0 cds                   | –
            // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
            // 37          | CALLDATACOPY          |                         | [0 - cds): calldata

            // --- keep some values in stack ---
            // 3d          | RETURNDATASIZE        | 0                       | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0                     | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0 0                   | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | [0 - cds): calldata
            // 61 extra    | PUSH2 extra (e)       | e 0 0 0 0               | [0 - cds): calldata

            // --- copy extra data to memory ---
            // 80          | DUP1                  | e e 0 0 0 0             | [0 - cds): calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 e e 0 0 0 0        | [0 - cds): calldata
            // 36          | CALLDATASIZE          | cds 0x35 e e 0 0 0 0    | [0 - cds): calldata
            // 39          | CODECOPY              | e 0 0 0 0               | [0 - cds): calldata, [cds - cds + e): extraData

            // --- delegate call to the implementation contract ---
            // 36          | CALLDATASIZE          | cds e 0 0 0 0           | [0 - cds): calldata, [cds - cds + e): extraData
            // 01          | ADD                   | cds+e 0 0 0 0           | [0 - cds): calldata, [cds - cds + e): extraData
            // 3d          | RETURNDATASIZE        | 0 cds+e 0 0 0 0         | [0 - cds): calldata, [cds - cds + e): extraData
            // 73 addr     | PUSH20 addr           | addr 0 cds+e 0 0 0 0    | [0 - cds): calldata, [cds - cds + e): extraData
            // 5a          | GAS                   | gas addr 0 cds+e 0 0 0 0| [0 - cds): calldata, [cds - cds + e): extraData
            // f4          | DELEGATECALL          | success 0 0             | [0 - cds): calldata, [cds - cds + e): extraData

            // --- copy return data to memory ---
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0 - cds): calldata, [cds - cds + e): extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0 - cds): calldata, [cds - cds + e): extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0 - cds): calldata, [cds - cds + e): extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0 - cds): calldata, [cds - cds + e): extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0 - rds): returndata, ... the rest might be dirty

            // 60 0x33     | PUSH1 0x33            | 0x33 success 0 rds      | [0 - rds): returndata, ... the rest might be dirty
            // 57          | JUMPI                 | 0 rds                   | [0 - rds): returndata, ... the rest might be dirty

            // --- revert ---
            // fd          | REVERT                |                         | [0 - rds): returndata, ... the rest might be dirty

            // --- return ---
            // 5b          | JUMPDEST              | 0 rds                   | [0 - rds): returndata, ... the rest might be dirty
            // f3          | RETURN                |                         | [0 - rds): returndata, ... the rest might be dirty

            mstore(
                ptr,
                or(
                    // ⎬  ♠︎♠︎♠︎♠︎         ♣︎♣︎         ⎨           -              ♥︎♥︎♥︎♥︎-     ♦︎♦︎      -           >
                    hex"610000_3d_81_600a_3d_39_f3_36_3d_3d_37_3d_3d_3d_3d_610000_80_6035_36_39_36_01_3d_73",
                    or(shl(0xe8, runSize), shl(0x58, extraLength)) // ♠︎=runSize, ♥︎=extraLength
                )
            )

            mstore(add(ptr, 0x1e), shl(0x60, implementation))

            //                        >     -                 ☼☼   -        |
            mstore(add(ptr, 0x32), hex"5a_f4_3d_3d_93_80_3e_6033_57_fd_5b_f3")

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            let counter := mload(data)
            let copyPtr := add(ptr, BOOTSTRAP_LENGTH)
            let dataPtr := add(data, ONE_WORD)

            for {} true {} {
                if lt(counter, ONE_WORD) { break }

                mstore(copyPtr, mload(dataPtr))

                copyPtr := add(copyPtr, ONE_WORD)
                dataPtr := add(dataPtr, ONE_WORD)

                counter := sub(counter, ONE_WORD)
            }

            let mask := shl(mul(0x8, sub(ONE_WORD, counter)), not(0))

            mstore(copyPtr, and(mload(dataPtr), mask))
            copyPtr := add(copyPtr, counter)
            mstore(copyPtr, shl(0xf0, extraLength))

            // Update free memory pointer
            mstore(FREE_MEMORY_POINTER_SLOT, add(ptr, creationSize))
        }
    }
}

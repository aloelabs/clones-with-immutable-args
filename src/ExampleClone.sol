// SPDX-License-Identifier: BSD
pragma solidity ^0.8.15;

import {ImmutableArgs} from "./ImmutableArgs.sol";

contract ExampleClone {
    function param1() public pure returns (address) {
        return ImmutableArgs._getArgAddress(0);
    }

    function param2() public pure returns (uint256) {
        return ImmutableArgs._getArgUint256(20);
    }

    function param3() public pure returns (uint64) {
        return ImmutableArgs._getArgUint64(52);
    }

    function param4() public pure returns (uint8) {
        return ImmutableArgs._getArgUint8(60);
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.15;

import {ImmutableArgs} from "./ImmutableArgs.sol";

contract ExampleClone {
    function param1() public pure returns (address) {
        return ImmutableArgs.addressAt(0);
    }

    function param2() public pure returns (uint256) {
        return ImmutableArgs.uint256At(20);
    }

    function param3() public pure returns (uint64) {
        return uint64(ImmutableArgs.uint256At(52) >> 192);
    }

    function param4() public pure returns (uint8) {
        return uint8(ImmutableArgs.uint256At(60) >> 248);
    }

    function all(bytes memory main, bool flag) public pure returns (bytes memory) {
        if (flag) return ImmutableArgs.all();
        return main;
    }
}

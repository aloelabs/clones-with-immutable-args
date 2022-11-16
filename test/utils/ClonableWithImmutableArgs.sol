// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ImmutableArgs} from "../../src/ImmutableArgs.sol";

contract ClonableWithImmutableArgs {
    address public immutable actualImmutable;

    constructor(address actualImmutable_) {
        actualImmutable = actualImmutable_;
    }

    function readFakeImmutable() external pure returns (address) {
        return ImmutableArgs.addr();
    }

    function msgData(bytes memory input) external pure returns (bytes memory, bytes memory) {
        return (input, msg.data);
    }
}

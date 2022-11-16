// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ClonableEIP1167 {
    address public immutable actualImmutable;

    address private fakeImmutable;

    constructor(address actualImmutable_) {
        actualImmutable = actualImmutable_;
    }

    function initialize(address fakeImmutable_) external {
        require(fakeImmutable == address(0));
        fakeImmutable = fakeImmutable_;
    }

    function readFakeImmutable() external view returns (address) {
        return fakeImmutable;
    }

    function msgData(bytes memory input) external pure returns (bytes memory, bytes memory) {
        return (input, msg.data);
    }
}

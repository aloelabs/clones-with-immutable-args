// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ClonableEIP1167 {
    address public immutable actualImmutable;

    address private _fakeImmutable;

    constructor(address actualImmutable_) {
        actualImmutable = actualImmutable_;
    }

    function initialize(address fakeImmutable) external {
        require(_fakeImmutable == address(0), "Already initialized");
        _fakeImmutable = fakeImmutable;
    }

    function readFakeImmutable() external view returns (address) {
        return _fakeImmutable;
    }

    function msgData(bytes memory input) external pure returns (bytes memory, bytes memory) {
        return (input, msg.data);
    }
}

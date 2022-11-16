// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Clones} from "../../src/Clones.sol";
import {ClonesWithImmutableArgs} from "../../src/ClonesWithImmutableArgs.sol";

import {ClonableEIP1167} from "./ClonableEIP1167.sol";
import {ClonableWithImmutableArgs} from "./ClonableWithImmutableArgs.sol";

contract Factory {
    ClonableEIP1167 public immutable implementationA;

    ClonableWithImmutableArgs public immutable implementationB;

    constructor(address actualImmutable) {
        implementationA = new ClonableEIP1167(actualImmutable);
        implementationB = new ClonableWithImmutableArgs(actualImmutable);
    }

    function cloneEIP1167(address fakeImmutable, bool deterministic) external returns (address clone) {
        bytes32 salt = _getSalt(fakeImmutable);

        if (deterministic) clone = Clones.cloneDeterministic(address(implementationA), salt);
        else clone = Clones.clone(address(implementationA));

        ClonableEIP1167(clone).initialize(fakeImmutable);
    }

    function cloneWithImmutableArgs(address fakeImmutable, bool deterministic) external returns (address clone) {
        bytes32 salt = _getSalt(fakeImmutable);
        bytes memory args = abi.encodePacked(fakeImmutable);

        if (deterministic) clone = ClonesWithImmutableArgs.cloneDeterministic(address(implementationB), salt, args);
        else clone = ClonesWithImmutableArgs.clone(address(implementationB), args);
    }

    function _getSalt(address fakeImmutable) private pure returns (bytes32 salt) {
        salt = keccak256(abi.encode(fakeImmutable));
    }
}

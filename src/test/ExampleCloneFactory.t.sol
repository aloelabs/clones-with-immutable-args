// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

import {ExampleClone} from "../ExampleClone.sol";
import {ExampleCloneFactory} from "../ExampleCloneFactory.sol";

contract ExampleCloneFactoryTest is Test {
    ExampleCloneFactory internal factory;

    function setUp() public {
        ExampleClone implementation = new ExampleClone();
        factory = new ExampleCloneFactory(implementation);
    }

    /// -----------------------------------------------------------------------
    /// Gas benchmarking
    /// -----------------------------------------------------------------------

    function testGas_clone(address param1, uint256 param2, uint64 param3, uint8 param4) public {
        factory.createClone(param1, param2, param3, param4);
    }

    /// -----------------------------------------------------------------------
    /// Correctness tests
    /// -----------------------------------------------------------------------

    function testCorrectness_clone(address param1, uint256 param2, uint64 param3, uint8 param4) public {
        ExampleClone clone = factory.createClone(param1, param2, param3, param4);
        assertEq(clone.param1(), param1);
        assertEq(clone.param2(), param2);
        assertEq(clone.param3(), param3);
        assertEq(clone.param4(), param4);
    }

    function testCalldataCorrectness_clone(address p1, uint256 p2, uint64 p3, uint8 p4, bytes memory main) public {
        ExampleClone clone = factory.createClone(p1, p2, p3, p4);

        bytes memory extra = abi.encodePacked(p1, p2, p3, p4);
        assertEq(clone.all(main, false), main);
        assertEq(clone.all(main, true), extra);
    }
}

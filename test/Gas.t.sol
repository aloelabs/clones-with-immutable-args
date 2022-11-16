// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import "./utils/Factory.sol";

contract GasTest is Test {
    Factory public factory;

    ClonableEIP1167 public cloneA;

    ClonableWithImmutableArgs public cloneB;

    function setUp() public {
        factory = new Factory(address(1));
        cloneA = ClonableEIP1167(factory.cloneEIP1167(address(this), false));
        cloneB = ClonableWithImmutableArgs(factory.cloneWithImmutableArgs(address(this), false));
    }

    /// -----------------------------------------------------------------------
    /// Gas benchmarking
    /// -----------------------------------------------------------------------

    function testGas_deploy_eip1167() public {
        factory.cloneEIP1167(address(this), false);
    }

    function testGas_deploy_args() public {
        factory.cloneWithImmutableArgs(address(this), false);
    }

    function testGas_deployDeterministic_eip1167() public {
        factory.cloneEIP1167(address(this), true);
    }

    function testGas_deployDeterministic_args() public {
        factory.cloneWithImmutableArgs(address(this), true);
    }

    function testGas_actualImmutable_eip1167() public view {
        cloneA.actualImmutable();
    }

    function testGas_actualImmutable_args() public view {
        cloneB.actualImmutable();
    }

    function testGas_fakeImmutable_eip1167() public view {
        cloneA.readFakeImmutable();
    }

    function testGas_fakeImmutable_args() public view {
        cloneB.readFakeImmutable();
    }
}

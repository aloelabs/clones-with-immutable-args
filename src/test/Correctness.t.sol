// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

import "./utils/Factory.sol";

contract GasTest is Test {
    function setUp() public {}

    function testCorrectness_eip1167(address actualImmutable, address fakeImmutable, bool deterministic, bytes memory rand) public {
        Factory factory = new Factory(actualImmutable);
        ClonableEIP1167 clone = ClonableEIP1167(factory.cloneEIP1167(fakeImmutable, deterministic));
        
        assertEq(clone.actualImmutable(), actualImmutable);
        assertEq(clone.readFakeImmutable(), fakeImmutable);

        ClonableEIP1167 impl = factory.implementationA();
        assertEq(impl.actualImmutable(), actualImmutable);
        assertEq(impl.readFakeImmutable(), address(0));

        (bytes memory received, ) = clone.msgData(rand);
        assertEq(received, rand);

        if (deterministic) {
            bytes32 salt = keccak256(abi.encode(fakeImmutable));
            assertEq(address(clone), Clones.predictDeterministicAddress(address(impl), salt, address(factory)));
        }
    }

    function testCorrectness_immutableArgs(address actualImmutable, address fakeImmutable, bool deterministic, bytes memory rand) public {
        Factory factory = new Factory(actualImmutable);
        ClonableWithImmutableArgs clone = ClonableWithImmutableArgs(factory.cloneWithImmutableArgs(fakeImmutable, deterministic));
        
        assertEq(clone.actualImmutable(), actualImmutable);
        assertEq(clone.readFakeImmutable(), fakeImmutable);

        ClonableWithImmutableArgs impl = factory.implementationB();
        assertEq(impl.actualImmutable(), actualImmutable);
        assertEq(impl.readFakeImmutable(), address(0));

        (bytes memory received, bytes memory msgData) = clone.msgData(rand);
        assertEq(received, rand);

        bytes memory func = abi.encodeWithSelector(ClonableWithImmutableArgs.msgData.selector, rand);
        bytes memory addr = abi.encodePacked(fakeImmutable);
        bytes memory expected = new bytes(func.length + addr.length + 2);

        uint256 k;
        uint256 i;
        for (i = 0; i < func.length; i++) {
            expected[k] = func[i];
            k++;
        }
        for (i = 0; i < addr.length; i++) {
            expected[k] = addr[i];
            k++;
        }
        expected[k] = 0x00;
        expected[k+1] = 0x16; // 0x16==22. Appended calldata has 20 bytes for address and 2 bytes for storing length

        assertEq(msgData, expected);

        if (deterministic) {
            bytes32 salt = keccak256(abi.encode(fakeImmutable));
            assertEq(address(clone), ClonesWithImmutableArgs.predictDeterministicAddress(address(impl), salt, address(factory), addr));
        }
    }
}

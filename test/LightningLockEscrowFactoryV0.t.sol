// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "src/LightningLockFactoryV0.sol";
import "src/X.sol";

contract TestContract is Test {
    LightningLockEscrow _c;
    LightningLockFactoryV0 _f;
    IERC20 _xToken;
    address _owner;
    address payable _depositor;
    address payable _destAddress;
    bytes32 _paymentHash;
    bytes _preimage;

    function hexStringToBytes(
        string memory hexString
    ) public pure returns (bytes memory) {
        // Ensure that the input string has an even number of characters
        require(
            bytes(hexString).length % 2 == 0,
            "Hex string length must be even"
        );

        // Remove the "0x" prefix if it exists
        if (bytes(hexString)[0] == "0" && bytes(hexString)[1] == "x") {
            hexString = _substring(hexString, 2);
        }

        // Calculate the length of the resulting bytes array
        uint256 length = bytes(hexString).length / 2;

        // Initialize a new bytes memory with the calculated length
        bytes memory byteArray = new bytes(length);

        // Iterate through the input hex string, converting pairs of characters to bytes
        for (uint256 i = 0; i < length; i++) {
            byteArray[i] = bytes1(
                uint8(_hexCharToUint(hexString, i * 2)) *
                    16 +
                    uint8(_hexCharToUint(hexString, i * 2 + 1))
            );
        }

        return byteArray;
    }

    // Utility function to convert a single hexadecimal character to a uint
    function _hexCharToUint(
        string memory hexString,
        uint256 index
    ) internal pure returns (uint8) {
        bytes1 char = bytes(hexString)[index];
        if (char >= bytes1("0") && char <= bytes1("9")) {
            return uint8(char) - uint8(bytes1("0"));
        } else if (char >= bytes1("a") && char <= bytes1("f")) {
            return uint8(char) - uint8(bytes1("a")) + 10;
        } else if (char >= bytes1("A") && char <= bytes1("F")) {
            return uint8(char) - uint8(bytes1("A")) + 10;
        } else {
            revert("Invalid hexadecimal character");
        }
    }

    // Utility function to extract a substring from a string
    function _substring(
        string memory str,
        uint256 startIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex < strBytes.length, "Start index out of bounds");

        bytes memory result = new bytes(strBytes.length - startIndex);
        for (uint256 i = startIndex; i < strBytes.length; i++) {
            result[i - startIndex] = strBytes[i];
        }

        return string(result);
    }

    function setUp() public {
        _owner = vm.addr(0x444);
        _depositor = payable(vm.addr(0x123));
        _destAddress = payable(vm.addr(0x234));
        _preimage = hexStringToBytes(
            "9d9459f488354dd33e1d62fcd7b457d38c6cdb58102a221f31aa9e99bbc47657"
        );
        _paymentHash = sha256(_preimage); // 69d6788dea734d195656858726cec13c85ab0b8ea40d30ff816be135bc9f6f94
        vm.prank(_depositor);
        _xToken = new X(500000);
        vm.prank(_owner);
    }

    function testCreateEscrow() public {
        console.logBytes32(_paymentHash);

        _f = new LightningLockFactoryV0();
        _c = _f.createEscrow(
            _depositor,
            _destAddress,
            _paymentHash,
            _xToken,
            500000
        );
        vm.prank(_depositor);
        _xToken.approve(address(_c), 500000);
        vm.prank(_depositor);
        _c.deposit();
        assertEq(_xToken.balanceOf(address(_c)), 500000);
        vm.prank(_depositor);
        _c.releaseWithPreimage(_preimage);
        assertEq(_xToken.balanceOf(_destAddress), 500000);
        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_xToken.balanceOf(address(_depositor)), 0);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/LightningLockEscrow.sol";
import "src/X.sol";

contract TestContract is Test {
    LightningLockEscrow _c;
    IERC20 _xToken;

    address _owner;
    address payable _depositor;
    address payable _destAddress;
    bytes32 _paymentHash;
    bytes32 _preimage;

    function setUp() public {
        _owner = vm.addr(0x444);
        _depositor = payable(vm.addr(0x123));
        _destAddress = payable(vm.addr(0x234));
        _preimage = "preimage";
        _paymentHash = keccak256(abi.encodePacked(_preimage));
        vm.prank(_depositor);
        _xToken = new X(500000);
        vm.prank(_owner);
    }

    function testSwap() public {
        _c = new LightningLockEscrow(
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

    function testAbort() public {
        _c = new LightningLockEscrow(
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
        vm.roll(block.number + 100834);
        vm.prank(_depositor);
        _c.abort();

        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_xToken.balanceOf(_depositor), 500000);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/OpenEscrow.sol";
import "src/X.sol";
import "src/Y.sol";

contract TestContract is Test {
    OpenEscrow _c;
    IERC20 _xToken;
    IERC20 _yToken;

    address _owner;
    address payable _buyer;
    address payable _seller;
    address payable _kickback;

    function setUp() public {
        _owner = vm.addr(0x444);
        _kickback = payable(vm.addr(0x888));
        _buyer = payable(vm.addr(0x123));
        _seller = payable(vm.addr(0x234));
        vm.prank(_buyer);
        _xToken = new X(9999999999); // _buyer starts with 100 X
        vm.prank(_seller);
        _yToken = new Y(9999999999); // _seller starts with 100 Y
        vm.prank(_owner);
    }

    function testSwap() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_buyer);
        _xToken.approve(address(_c), 500000);
        vm.prank(_buyer);
        _c.buyerDeposit();
        assertEq(_xToken.balanceOf(address(_c)), 500000);
        vm.prank(_seller);
        _yToken.approve(address(_c), 500000);
        vm.prank(_seller);
        _c.sellerDeposit();
        assertEq(_yToken.balanceOf(address(_c)), 500000);
        vm.prank(_owner);
        _c.releaseAssets(_kickback);

        assertEq(_xToken.balanceOf(_seller), 499925);
        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(_buyer), 499925);
        assertEq(_xToken.balanceOf(_kickback), 75);
        assertEq(_xToken.balanceOf(_kickback), 75);
    }

    function testSwapSmall() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 100, _yToken, 100);
        vm.prank(_buyer);
        _xToken.approve(address(_c), 100);
        vm.prank(_buyer);
        _c.buyerDeposit();
        assertEq(_xToken.balanceOf(address(_c)), 100);
        vm.prank(_seller);
        _yToken.approve(address(_c), 100);
        vm.prank(_seller);
        _c.sellerDeposit();
        assertEq(_yToken.balanceOf(address(_c)), 100);
        vm.prank(_owner);
        _c.releaseAssets(_kickback);

        assertEq(_xToken.balanceOf(_seller), 100);
        assertEq(_yToken.balanceOf(_buyer), 100);
        assertEq(_xToken.balanceOf(_kickback), 0);
        assertEq(_xToken.balanceOf(_kickback), 0); // fee is smaller than the smallest division of the token
        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }

    function testFailSwapBuyerDeposit() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_buyer);
        _xToken.approve(address(_c), 500000);
        vm.prank(_buyer);
        _c.buyerDeposit();
        assertEq(_xToken.balanceOf(address(_c)), 500000);
        vm.prank(_buyer);
        _c.releaseAssets(_kickback);
        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }

    function testFailSwapSellerDeposit() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_seller);
        _yToken.approve(address(_c), 500000);
        vm.prank(_seller);
        _c.sellerDeposit();
        assertEq(_yToken.balanceOf(address(_c)), 500000);
        vm.prank(_seller);
        _c.releaseAssets(_kickback);
        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }

    function testAbortBothDepositors() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_buyer);
        _xToken.approve(address(_c), 500000);
        vm.prank(_buyer);
        _c.buyerDeposit();
        assertEq(_xToken.balanceOf(address(_c)), 500000);
        vm.prank(_seller);
        _yToken.approve(address(_c), 500000);
        vm.prank(_seller);
        _c.sellerDeposit();
        assertEq(_yToken.balanceOf(address(_c)), 500000);
        vm.roll(block.number + 100834);
        vm.prank(_seller);
        _c.abort();

        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }

    function testAbortBuyerDepositor() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_buyer);
        _xToken.approve(address(_c), 500000);
        vm.prank(_buyer);
        _c.buyerDeposit();
        assertEq(_xToken.balanceOf(address(_c)), 500000);

        vm.roll(block.number + 100834);
        vm.prank(_seller);
        _c.abort();

        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }

    function testAbortSellerDepositor() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_seller);
        _yToken.approve(address(_c), 500000);
        vm.prank(_seller);
        _c.sellerDeposit();
        assertEq(_yToken.balanceOf(address(_c)), 500000);
        vm.roll(block.number + 100834);
        vm.prank(_seller);
        _c.abort();

        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }

    function testFailAbort() public {
        _c = new OpenEscrow(_buyer, _seller, _xToken, 500000, _yToken, 500000);
        vm.prank(_buyer);
        _xToken.approve(address(_c), 500000);
        vm.prank(_buyer);
        _c.buyerDeposit();
        assertEq(_xToken.balanceOf(address(_c)), 500000);
        vm.prank(_seller);
        _yToken.approve(address(_c), 500000);
        vm.prank(_seller);
        _c.sellerDeposit();
        assertEq(_yToken.balanceOf(address(_c)), 500000);
        vm.roll(block.number + 100833); //100833 fails here
        vm.prank(_seller);
        _c.abort();
        assertEq(_xToken.balanceOf(address(_c)), 0);
        assertEq(_yToken.balanceOf(address(_c)), 0);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/OpenEscrow.sol";
import "src/X.sol";
import "src/Y.sol";

contract TestContract is Test {
    OpenEscrow c;
    IERC20 x_token;
    IERC20 y_token;

    address owner;
    address payable buyer;
    address payable seller;
    address payable kickback;

    function setUp() public {
        owner = vm.addr(0x444);
        kickback = payable(vm.addr(0x888));
        buyer = payable(vm.addr(0x123));
        seller = payable(vm.addr(0x234));
        vm.prank(buyer);
        x_token = new X(9999999999); // buyer starts with 100 X
        vm.prank(seller);
        y_token = new Y(9999999999); // seller starts with 100 Y
        vm.prank(owner);
        
    }

    function testSwap() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(buyer);
        x_token.approve(address(c), 500000);
        vm.prank(buyer);
        c.buyerDeposit();
        assertEq(x_token.balanceOf(address(c)), 500000);
        vm.prank(seller);
        y_token.approve(address(c), 500000);
        vm.prank(seller);
        c.sellerDeposit();
        assertEq(y_token.balanceOf(address(c)), 500000);
        vm.prank(owner);
        c.releaseAssets(kickback);

        assertEq(x_token.balanceOf(seller), 499925);
        assertEq(y_token.balanceOf(buyer), 499925);
        assertEq(x_token.balanceOf(kickback), 75);
        assertEq(x_token.balanceOf(kickback), 75);
    }

    function testSwap_Small() public {
        c = new OpenEscrow(buyer, seller, x_token, 100, y_token, 100);
        vm.prank(buyer);
        x_token.approve(address(c), 100);
        vm.prank(buyer);
        c.buyerDeposit();
        assertEq(x_token.balanceOf(address(c)), 100);
        vm.prank(seller);
        y_token.approve(address(c), 100);
        vm.prank(seller);
        c.sellerDeposit();
        assertEq(y_token.balanceOf(address(c)), 100);
        vm.prank(owner);
        c.releaseAssets(kickback);

        assertEq(x_token.balanceOf(seller), 100);
        assertEq(y_token.balanceOf(buyer), 100);
        assertEq(x_token.balanceOf(kickback), 0);
        assertEq(x_token.balanceOf(kickback), 0); // fee is smaller than the smallest division of the token
    }

    function testFailSwap_BuyerDeposit() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(buyer);
        x_token.approve(address(c), 500000);
        vm.prank(buyer);
        c.buyerDeposit();
        assertEq(x_token.balanceOf(address(c)), 500000);
        vm.prank(buyer);
        c.releaseAssets(kickback);
    }

    function testFailSwap_SellerDeposit() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(seller);
        y_token.approve(address(c), 500000);
        vm.prank(seller);
        c.sellerDeposit();
        assertEq(y_token.balanceOf(address(c)), 500000);
        vm.prank(seller);
        c.releaseAssets(kickback);
    }

    function testAbort_BothDepositors() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(buyer);
        x_token.approve(address(c), 500000);
        vm.prank(buyer);
        c.buyerDeposit();
        assertEq(x_token.balanceOf(address(c)), 500000);
        vm.prank(seller);
        y_token.approve(address(c), 500000);
        vm.prank(seller);
        c.sellerDeposit();
        assertEq(y_token.balanceOf(address(c)), 500000);
        vm.roll(block.number + 100834);
        vm.prank(seller);
        c.abort();

        assertEq(x_token.balanceOf(address(c)), 0);
        assertEq(y_token.balanceOf(address(c)), 0);
    }

    function testAbort_BuyerDepositor() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(buyer);
        x_token.approve(address(c), 500000);
        vm.prank(buyer);
        c.buyerDeposit();
        assertEq(x_token.balanceOf(address(c)), 500000);

        vm.roll(block.number + 100834);
        vm.prank(seller);
        c.abort();

        assertEq(x_token.balanceOf(address(c)), 0);
        assertEq(y_token.balanceOf(address(c)), 0);
    }

    function testAbort_SellerDepositor() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(seller);
        y_token.approve(address(c), 500000);
        vm.prank(seller);
        c.sellerDeposit();
        assertEq(y_token.balanceOf(address(c)), 500000);
        vm.roll(block.number + 100834);
        vm.prank(seller);
        c.abort();

        assertEq(x_token.balanceOf(address(c)), 0);
        assertEq(y_token.balanceOf(address(c)), 0);
    }

    function testFailAbort() public {
        c = new OpenEscrow(buyer, seller, x_token, 500000, y_token, 500000);
        vm.prank(buyer);
        x_token.approve(address(c), 500000);
        vm.prank(buyer);
        c.buyerDeposit();
        assertEq(x_token.balanceOf(address(c)), 500000);
        vm.prank(seller);
        y_token.approve(address(c), 500000);
        vm.prank(seller);
        c.sellerDeposit();
        assertEq(y_token.balanceOf(address(c)), 500000);
        vm.roll(block.number + 100833); //100833 fails here
        vm.prank(seller);
        c.abort();
    }
}

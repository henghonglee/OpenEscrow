// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./SimpleEscrow.sol";

contract EscrowFactory {
    SimpleEscrow[] public contracts;

    event EscrowCreated(address escrowAddress, address indexed buyer, address indexed seller, uint256 price);

    function createEscrow(address payable buyer, address payable seller, uint256 price) public {
        SimpleEscrow escrow = new SimpleEscrow(buyer, seller, price);
        contracts.push(escrow);
        emit EscrowCreated(address(escrow), buyer, seller, price);
    }

    function getDeployedEscrows() public view returns (SimpleEscrow[] memory) {
        return contracts;
    }
}
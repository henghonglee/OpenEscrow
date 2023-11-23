// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./OpenEscrow.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract OpenEscrowFactoryV0 {
    OpenEscrow[] public contracts;

    event EscrowCreated(
        address indexed buyer,
        address indexed seller,
        ERC20 buyerToken,
        uint256 buyerTokenAmount,
        ERC20 sellerToken,
        uint256 sellerTokenAmount
    );

    function createEscrow(
        address payable buyer,
        address payable seller,
        ERC20 buyerToken,
        uint256 buyerTokenAmount,
        ERC20 sellerToken,
        uint256 sellerTokenAmount
    ) public {
        OpenEscrow escrow = new OpenEscrow(
            buyer,
            seller,
            buyerToken,
            buyerTokenAmount,
            sellerToken,
            sellerTokenAmount
        );
        contracts.push(escrow);
        emit EscrowCreated(
            buyer,
            seller,
            buyerToken,
            buyerTokenAmount,
            sellerToken,
            sellerTokenAmount
        );
    }

    function getDeployedEscrows() public view returns (OpenEscrow[] memory) {
        return contracts;
    }
}

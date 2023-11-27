// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./LightningLockEscrowV0.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LightningLockFactoryV0 {
    LightningLockEscrow[] public contracts;

    event EscrowCreated(
        address indexed escrowAddress,
        address indexed depositor,
        address indexed destAddress,
        IERC20 token,
        uint256 tokenAmount
    );

    function createEscrow(
        address payable depositor,
        address payable destAddress,
        bytes32 paymentHash, // should enforce non-reuse of preimages
        IERC20 token,
        uint256 tokenAmount
    ) public returns (LightningLockEscrow) {
        LightningLockEscrow escrow = new LightningLockEscrow(
            depositor,
            destAddress,
            paymentHash,
            token,
            tokenAmount
        );
        contracts.push(escrow);
        emit EscrowCreated(
            address(escrow),
            depositor,
            destAddress,
            token,
            tokenAmount
        );
        return escrow;
    }

    function getDeployedEscrows()
        public
        view
        returns (LightningLockEscrow[] memory)
    {
        return contracts;
    }
}

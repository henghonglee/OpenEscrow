// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./LightningLockEscrow.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LightningLockFactoryAlpha {
    LightningLockEscrow[] public contracts;

    event EscrowCreated(
        address indexed depositor,
        address indexed destAddress,
        ERC20 token,
        uint256 tokenAmount
    );

    function createEscrow(
        address payable depositor,
        address payable destAddress,
        bytes32 paymentHash,
        ERC20 token,
        uint256 tokenAmount
    ) public {
        LightningLockEscrow escrow = new LightningLockEscrow(
            depositor,
            destAddress,
            paymentHash,
            token,
            tokenAmount
        );
        contracts.push(escrow);
        emit EscrowCreated(
            depositor,
            destAddress,
            token,
            tokenAmount
        );
    }

    function getDeployedEscrows() public view returns (LightningLockEscrow[] memory) {
        return contracts;
    }
}

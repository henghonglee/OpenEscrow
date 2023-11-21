// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract LightningLockEscrow {
    using SafeERC20 for IERC20;
    address payable public depositor;
    address payable public destAddress;
    uint256 public deployedBlockNumber;
    uint256 public expiredBlockNumber;
    bytes32 public paymentHash;
    IERC20 public token;
    uint256 public tokenAmount; // this is the lowest decimal for erc20 token, buyerToken. take note for frontend
    State public state;

    enum State {
        Created,
        Deposited,
        Aborted,
        AssetsReleased
    }

    event Deposited();
    event Aborted();
    event AssetsReleased();

    constructor(
        address payable _depositor,
        address payable _destAddress,
        bytes32 _paymentHash,
        IERC20 _token,
        uint256 _tokenAmount
    ) {
        require(_tokenAmount > 0, "tokenAmount cannot be 0");
        depositor = _depositor;
        destAddress = _destAddress;
        paymentHash = _paymentHash;
        token = _token;
        tokenAmount = _tokenAmount;
        deployedBlockNumber = block.number;
        expiredBlockNumber = block.number + 100833; // approx 2 weeks for 12seconds per block
    }

    function deposit()
        public
        onlyDepositor
        inState(State.Created)
        returns (bool)
    {
        require(state == State.Created, "Invalid state.");
        token.safeTransferFrom(depositor, address(this), tokenAmount);
        state = State.Deposited;
        emit Deposited();
        return true;
    }

    // Function to release funds using the Lightning preimage
    function releaseWithPreimage(
        bytes32 preimage
    ) public inState(State.Deposited) {
        require(
            keccak256(abi.encodePacked(preimage)) == paymentHash,
            "Invalid preimage"
        );
        token.safeTransfer(destAddress, tokenAmount);
        state = State.AssetsReleased;
        emit AssetsReleased();
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Only buyer can call this.");
        _;
    }

    modifier onlyExpired() {
        require(
            block.number > expiredBlockNumber,
            "Only callable after expiration"
        );
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }
}

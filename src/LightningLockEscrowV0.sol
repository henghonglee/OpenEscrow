// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

enum State {
    Created,
    Deposited,
    Aborted,
    AssetsReleased
}

struct Entry {
    address payable depositor;
    address payable destAddress;
    uint256 deployedBlockNumber;
    uint256 expiredBlockNumber;
    bytes32 paymentHash;
    IERC20 token;
    uint256 tokenAmount; // this is the lowest decimal for erc20 token, buyerToken. take note for frontend
    State state;
}

contract LightningLockEscrow {
    using SafeERC20 for IERC20;
    mapping(uint256 => Entry) _jobIdToEntry;
    uint256 _currJobId = 0;

    event Deposited(bytes32 paymentHash);
    event Aborted();
    event AssetsReleased(bytes preimage);

    constructor() {}

    function createJobAndDeposit(
        uint256 _jobId,
        address payable _depositor,
        address payable _destAddress,
        bytes32 _paymentHash,
        IERC20 _token,
        uint256 _tokenAmount
    ) public returns (uint256) {
        require(_currJobId <= _jobId, "JobId already exists");

        uint256 jId = createJob(
            _depositor,
            _destAddress,
            _paymentHash,
            _token,
            _tokenAmount
        );

        deposit(jId);
        return jId;
    }

    function createJob(
        address payable _depositor,
        address payable _destAddress,
        bytes32 _paymentHash,
        IERC20 _token,
        uint256 _tokenAmount
    ) public returns (uint256) {
        _jobIdToEntry[_currJobId].depositor = _depositor;
        _jobIdToEntry[_currJobId].destAddress = _destAddress;
        _jobIdToEntry[_currJobId].deployedBlockNumber = block.number;
        _jobIdToEntry[_currJobId].expiredBlockNumber = block.number + 100833;
        _jobIdToEntry[_currJobId].paymentHash = _paymentHash;
        _jobIdToEntry[_currJobId].token = _token;
        _jobIdToEntry[_currJobId].tokenAmount = _tokenAmount;
        _currJobId += 1;
        return _currJobId;
    }

    function deposit(
        uint256 _jobId
    )
        public
        onlyDepositor(_jobId)
        inState(_jobId, State.Created)
        returns (bool)
    {
        Entry memory entry = _jobIdToEntry[_jobId];
        require(entry.state == State.Created, "Invalid state.");
        entry.token.safeTransferFrom(
            entry.depositor,
            address(this),
            entry.tokenAmount
        );
        entry.state = State.Deposited;
        emit Deposited(entry.paymentHash);
        return true;
    }

    // Function to release funds using the Lightning preimage
    function releaseWithPreimage(
        uint256 jobId,
        bytes memory preimage
    ) public inState(jobId, State.Deposited) {
        Entry memory entry = _jobIdToEntry[_currJobId];
        require(sha256(preimage) == entry.paymentHash, "Invalid preimage");
        entry.token.safeTransfer(entry.destAddress, entry.tokenAmount);
        entry.state = State.AssetsReleased;
        emit AssetsReleased(preimage);
    }

    // anyone can abort if the transaction is expired
    // function abort() public onlyExpired returns (bool) {
    //     if (entrytoken.balanceOf(address(this)) == tokenAmount) {
    //         token.safeTransfer(depositor, tokenAmount);
    //     }
    //     emit Aborted();
    //     state = State.Aborted;
    //     return true;
    // }

    modifier onlyDepositor(uint256 jobId) {
        Entry memory entry = _jobIdToEntry[_currJobId];
        require(msg.sender == entry.depositor, "Only buyer can call this.");
        _;
    }

    modifier onlyExpired(uint256 jobId) {
        Entry memory entry = _jobIdToEntry[_currJobId];
        require(
            block.number > entry.expiredBlockNumber,
            "Only callable after expiration"
        );
        _;
    }

    modifier inState(uint256 jobId, State _state) {
        Entry memory entry = _jobIdToEntry[_currJobId];
        require(entry.state == _state, "Invalid state.");
        _;
    }
}

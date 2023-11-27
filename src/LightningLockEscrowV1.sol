// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "forge-std/console.sol";
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

    uint256 _currJobId = 0;
    mapping(uint256 => Entry) _jobIdToEntry;

    event Deposited(bytes32 paymentHash);
    event Aborted();
    event AssetsReleased(bytes preimage);

    constructor() {}

    function createJobAndDeposit(
        address payable _depositor,
        address payable _destAddress,
        bytes32 _paymentHash,
        IERC20 _token,
        uint256 _tokenAmount
    ) public returns (uint256) {
        uint256 j = createJob(
            _depositor,
            _destAddress,
            _paymentHash,
            _token,
            _tokenAmount
        );
        deposit(j);
        return j;
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
        return _currJobId++;
    }

    function deposit(
        uint256 jobId
    ) public onlyDepositor(jobId) inState(jobId, State.Created) returns (bool) {
        require(_jobIdToEntry[jobId].state == State.Created, "Invalid state.");
        _jobIdToEntry[jobId].token.safeTransferFrom(
            _jobIdToEntry[jobId].depositor,
            address(this),
            _jobIdToEntry[jobId].tokenAmount
        );
        _jobIdToEntry[jobId].state = State.Deposited;
        emit Deposited(_jobIdToEntry[jobId].paymentHash);
        return true;
    }

    // Function to release funds using the Lightning preimage
    function releaseWithPreimage(
        uint256 jobId,
        bytes memory preimage
    ) public inState(jobId, State.Deposited) {
        require(
            sha256(preimage) == _jobIdToEntry[jobId].paymentHash,
            "Invalid preimage"
        );
        _jobIdToEntry[jobId].token.safeTransfer(
            _jobIdToEntry[jobId].destAddress,
            _jobIdToEntry[jobId].tokenAmount
        );
        _jobIdToEntry[jobId].state = State.AssetsReleased;
        emit AssetsReleased(preimage);
    }

    // anyone can abort if the transaction is expired
    function abort(uint256 jobId) public onlyExpired(jobId) returns (bool) {
        if (
            _jobIdToEntry[jobId].token.balanceOf(address(this)) ==
            _jobIdToEntry[jobId].tokenAmount
        ) {
            _jobIdToEntry[jobId].token.safeTransfer(
                _jobIdToEntry[jobId].depositor,
                _jobIdToEntry[jobId].tokenAmount
            );
        }
        emit Aborted();
        _jobIdToEntry[jobId].state = State.Aborted;
        return true;
    }

    modifier onlyDepositor(uint256 jobId) {
        require(
            msg.sender == _jobIdToEntry[jobId].depositor,
            "Only buyer can call this."
        );
        _;
    }

    modifier onlyExpired(uint256 jobId) {
        require(
            block.number > _jobIdToEntry[jobId].expiredBlockNumber,
            "Only callable after expiration"
        );
        _;
    }

    modifier inState(uint256 jobId, State _state) {
        require(_jobIdToEntry[jobId].state == _state, "Invalid state. ");
        _;
    }
}

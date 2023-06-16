// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract OpenEscrow {
    using SafeERC20 for IERC20;

    address payable public buyer;
    address payable public seller;
    uint256 public deployedBlockNumber;
    uint256 public expiredBlockNumber;
    IERC20 public buyerToken;
    IERC20 public sellerToken;
    uint256 public buyerTokenAmount; // this is the lowest decimal for erc20 token, buyerToken. take note for frontend
    uint256 public sellerTokenAmount;
    State public state;

    enum State {
        Created,
        BuyerDeposited,
        SellerDeposited,
        BothDeposited,
        Aborted,
        AssetsReleased
    }

    event BuyerDeposited();
    event SellerDeposited();
    event Aborted();
    event AssetsReleased();

    constructor(
        address payable _buyer,
        address payable _seller,
        IERC20 _buyerToken,
        uint256 _buyerTokenAmount,
        IERC20 _sellerToken,
        uint256 _sellerTokenAmount
    ) {
        require(_buyerTokenAmount > 0, "buyerTokenAmount cannot be 0");
        require(_sellerTokenAmount > 0, "sellerTokenAmount cannot be 0");
        buyer = _buyer;
        seller = _seller;
        buyerTokenAmount = _buyerTokenAmount;
        sellerTokenAmount = _sellerTokenAmount;
        deployedBlockNumber = block.number;
        expiredBlockNumber = block.number + 100833; // approx 2 weeks for 12seconds per block
        buyerToken = _buyerToken;
        sellerToken = _sellerToken;
    }

    // Buyer Needs to Approve buyerTokenAmount for BuyerToken for this contract before use
    function buyerDeposit() public onlyBuyer returns (bool) {
        require((state == State.Created || state == State.SellerDeposited), "Invalid state.");
        buyerToken.safeTransferFrom(buyer, address(this), buyerTokenAmount);
        state = state == State.SellerDeposited ? State.BothDeposited : State.BuyerDeposited;
        emit BuyerDeposited();
        return true;
    }

    // Seller Needs to Approve sellerTokenAmount for SellerToken for this contract before use
    function sellerDeposit() public onlySeller returns (bool) {
        require((state == State.Created || state == State.BuyerDeposited), "Invalid state.");
        sellerToken.safeTransferFrom(seller, address(this), sellerTokenAmount);
        state = state == State.BuyerDeposited ? State.BothDeposited : State.SellerDeposited;
        emit SellerDeposited();
        return true;
    }

    // Anyone can call this release assets, we can even make a periodic system to release all possible escrows every 5min
    function releaseAssets(address payable kickback) public inState(State.BothDeposited) returns (bool) {
        uint256 buyerFee = _calculateFee(buyerTokenAmount, 15); // 0.00015 = 0.015% = 1.5 bps
        uint256 sellerFee = _calculateFee(sellerTokenAmount, 15);
        buyerToken.safeTransfer(seller, buyerTokenAmount - buyerFee);
        sellerToken.safeTransfer(buyer, sellerTokenAmount - sellerFee);
        buyerToken.safeTransfer(kickback, buyerFee);
        sellerToken.safeTransfer(kickback, sellerFee);
        // emit
        state = State.AssetsReleased;
        return true;
    }

    // anyone (buyer or seller) can abort if the transaction is expired
    function abort() public onlyBuyerOrSeller onlyExpired returns (bool) {
        if (buyerToken.balanceOf(address(this)) == buyerTokenAmount) {
            buyerToken.safeTransfer(buyer, buyerTokenAmount);
        }
        if (sellerToken.balanceOf(address(this)) == sellerTokenAmount) {
            sellerToken.safeTransfer(seller, sellerTokenAmount);
        }
        emit Aborted();
        state = State.Aborted;
        return true;
    }

    // rounded DOWN
    function _calculateFee(uint256 total, uint256 mbps) internal pure returns (uint256) {
        return ((total * mbps) / 100000);
    }

    modifier onlyBuyerOrSeller() {
        require((msg.sender == buyer || msg.sender == seller), "Only buyer or seller can call this.");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this.");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this.");
        _;
    }

    modifier onlyExpired() {
        require(block.number > expiredBlockNumber, "Only callable after expiration");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SimpleEscrow {
    address payable public buyer;
    address payable public seller;
    uint256 public price;
    enum State { Created, Locked, Release, Inactive }
    State public state;

    constructor(address payable _seller, uint256 _price) {
        buyer = payable(msg.sender);
        seller = _seller;
        price = _price;
    }

    modifier condition(bool _condition) {
        require(_condition);
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

    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();

    function abort()
        public
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    function confirmPurchase()
        public
        inState(State.Created)
        condition(msg.value == price)
        onlyBuyer
        payable
    {
        emit PurchaseConfirmed();
        state = State.Locked;
    }

    function confirmReceived()
        public
        onlyBuyer
        inState(State.Locked)
    {
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(price / 10);
        seller.transfer(address(this).balance);
    }
}
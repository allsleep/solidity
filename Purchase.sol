// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Purchase {
    uint public value;
    address payable public seller;
    address payable public buyer;

    enum State {Created, Locked, Release, Inactive}
    
    State public state;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "only buyer can call this");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "only seller can call this");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "invalid state");
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();

    // 确保是一个偶数
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        require((2 * value) == msg.value, "value has to be even");
    }

    //中止购买并回收以太币，只能在合约呗锁定之前由卖家调用
    function abort() public onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    // 买家确认购买，以太币锁定直到confirmReceived
    function confirmPurchase() public inState(State.Created)
        condition(msg.value == (2*value)) payable {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    function confirmReceived() public onlyBuyer inState(State.Locked){
        emit ItemReceived();
        state = State.Release;
        buyer.transfer(value);
    }

    function refundSeller() public onlySeller inState(State.Release){
        emit SellerRefunded();
        state = State.Inactive;
        seller.transfer(3 * value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    //取回之前的出价
    mapping(address => uint) pendingReturns;

    event AcutionEnded(address winner, uint highestBid);

    // 新的函数体是由modifier本身的函数体，并且原函数体替换'_;'语句来组成的
    modifier onlyBefore(uint _time) {require(block.timestamp < _time); _;}
    modifier onlyAfter (uint _time) {require(block.timestamp > _time); _;}
    
    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _beneficiary
    )public {
        beneficiary = _beneficiary;
        biddingEnd = block.timestamp + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }
    
    // 通过 '_blindedBid' = keccak256(value, fake, secret)设置秘密竞拍
    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({blindedBid: _blindedBid, deposit: msg.value}));
    }
    
    function reveal (uint[] _values, bool[] _fake, bytes32 _secret)
        public onlyAfter(biddingEnd) onlyBefore(revealEnd){
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bid = bids[msg.sender][i];
            (uint value. bool fake, bytes32 secret) = 
                (_values[i], _fake[i], _secret[i]);
            if (bid.blindedBid != keccak256(value, fake, secret)) {
                continue;
            }
            refund += bid.deposit;
            if (!fake && bid.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            bid.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund);
    }

    function placeBid(address bidder, uint value) internal returns (bool success){
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // 返回之前的最高出价
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    function auctionEnd() public onlyAfter(revealEnd) {
        require(!ended);
        emit AcutionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}

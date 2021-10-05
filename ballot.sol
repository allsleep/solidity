// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0

/// @title voting with delegation
contract ballot{
    // represent a single voter
    struct voter{
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }
    
    // type for a single proposal
    struct proposal{
        bytes32 name;
        uint voteCount; // get nummber of vote
    }

    address public chairperson;

    mapping(address => voter) public voters;

    proposal[] public proposals;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        // create a list of proposal
        // create a new proposal then put it in end of list
        for (uint i = 0; i < proposalNames.length; i++){
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }
    
    // only chairperson can call this function
    function giveRightToVoter(address voter) public {
        //require first argument is false will stop run current function
        require(msg.sender == chairperson, "only chairperson can give right to vote");
        require(!voters[voter].voted, "the voter already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    
    // delegate your vote right to "to"
    function delegate(address to) public {
        voter storage sender = voters[msg.sender];
        require(!sender.voted, "you already voted");
        
        require(to != msg.sender, "self-delegate is disallowed");

        // not recommand to delegate to delegate 
       while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "found loop");
       }

       // sender is a refrence of voters[msg.sender]
       sender.vote = true;
       sender.delegate = to;
       voter storage delegate_ = voters[to];
       if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += 1;
       } else {
            delegate_.weight += 1;
       }
    }


   function vote(uint proposal) public {
        voter storage sender = voters[msg.sender];
        require(!sender.voted, "already voted");
        sender.voted = true;
        sender.vote = proposal;

        // if proposal overflow the list, every change wil be canceled
        proposals[proposal].voteCount += sender.weight;
   } 

   /// @dev calculate the final winner taking all previous vote
   function winningProposal() public view returns (uint winningProposal_){
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++){
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
   }

   function winnerName() public view returns (bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
   }
}

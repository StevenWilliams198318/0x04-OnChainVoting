// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title An Election Voting smart contract
 * @author Steven Williams
 * @notice A smart contract for managing elections and voting
 */

contract ElectionVoting {

    /* Errors */
    error ElectionVoting_CandidateAlreadyExists();
    error ElectionVoting_VoterAlreadyVoted();
    error ElectionVoting_CandidateNotVoteItSelf();
    error ElectionVoting_NotAuthorized();
    error ElectionVoting_ElectionNotActive();
    error ElectionVoting_ElectionAlreadyActive();

    /* Events */
    event VotedForCandidate(address indexed voterAddress, address indexed candidateAddress);
    event CandidateAdded(string name, address indexed candidateAddress);
    event ProposalRegistered(bytes32 indexed proposalId, string name);
    event ElectionResults(string winner, address indexed winnerAddress, uint256 totalVotes);

    /* State Variables */
    address public electoralCommissioner;
    uint256 public totalCandidates;
    uint256 public totalVoters;
    bool public electionActive;
    address[] private candidateAddress;
    address[] private voterAddresses;

    // Mappings - Quick Lookups
    mapping(bytes32 => Candidate) public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => Voter) public currentvoters;
    mapping(bytes32 => address) private candidateAddressMap;
    Proposal[] public proposals;

    constructor() {
        electoralCommissioner = msg.sender; 
        electionActive = false; // Election starts as inactive
    }

    struct Voter {
        uint256 id;
        string name;
        address voterAddress;
        address candidateAddress;
    }

    struct Candidate {
        string name;
        bytes32 candidateId;
        uint256 voteCount;
    }

    struct Proposal {
        string name;
        address proposalCandidateAddress;
    }

    /* Modifiers */
    modifier onlyCommissioner() {
        if (msg.sender != electoralCommissioner) {
            revert ElectionVoting_NotAuthorized();
        }
        _;
    }

    modifier onlyDuringElection() {
        if (!electionActive) {
            revert ElectionVoting_ElectionNotActive();
        }
        _;
    }

    modifier onlyWhenElectionInactive() {
        if (electionActive) {
            revert ElectionVoting_ElectionAlreadyActive();
        }
        _;
    }

    function startElection() external onlyCommissioner onlyWhenElectionInactive {
        electionActive = true;
    }

    function stopElection() external onlyCommissioner onlyDuringElection {
        electionActive = false;
        emitElectionResults();
        resetElection();
    }

    function addCandidate(address _address, string memory _name) external onlyCommissioner onlyDuringElection {
        bytes32 candidatesId = keccak256(abi.encodePacked(_address));

        if (candidates[candidatesId].candidateId != bytes32(0)) {
            revert ElectionVoting_CandidateAlreadyExists();
        }

        candidates[candidatesId] = Candidate(_name, candidatesId, 0);
        candidateAddress.push(_address); // Storing candidate address for lookup
        candidateAddressMap[candidatesId] = _address; // Store original address for self-voting check
        totalCandidates++;
        emit CandidateAdded(_name, _address);
    }

    function vote(bytes32 _candidateId) external onlyDuringElection {
        if (hasVoted[msg.sender]) {
            revert ElectionVoting_VoterAlreadyVoted();
        }
        if (candidates[_candidateId].candidateId == bytes32(0)) {
            revert ElectionVoting_CandidateNotVoteItSelf();
        }

        // Ensure voter is not voting for themselves (check original address mapping)
        address candidateOriginalAddress = candidateAddressMap[_candidateId];
        if (msg.sender == candidateOriginalAddress) {
            revert ElectionVoting_CandidateNotVoteItSelf();
        }

        // Register vote
        candidates[_candidateId].voteCount++;
        currentvoters[msg.sender] = Voter(totalVoters, "Voter", msg.sender, candidateOriginalAddress);
        hasVoted[msg.sender] = true;
        voterAddresses.push(msg.sender);
        totalVoters++;

        emit VotedForCandidate(msg.sender, candidateOriginalAddress);
    }

    function emitElectionResults() internal {
        address winnerAddress;
        uint256 highestVoteCount = 0;
        string memory winnerName;

        for (uint256 i = 0; i < candidateAddress.length; i++) {
            bytes32 candId = keccak256(abi.encodePacked(candidateAddress[i]));
            Candidate memory candidate = candidates[candId];
            if (candidate.voteCount > highestVoteCount) {
                highestVoteCount = candidate.voteCount;
                winnerAddress = candidateAddress[i];
                winnerName = candidate.name;
            }
        }

        emit ElectionResults(winnerName, winnerAddress, totalVoters);
    }

    function resetElection() internal {
        // Clear candidates from the mapping
        for (uint256 i = 0; i < candidateAddress.length; i++) {
            bytes32 candId = keccak256(abi.encodePacked(candidateAddress[i]));
            delete candidates[candId];
        }
        // Clear the candidateAddress array completely
        while (candidateAddress.length > 0) {
            candidateAddress.pop();
        }

        totalCandidates = 0;
        totalVoters = 0;

        // Clear voter records
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            delete hasVoted[voterAddresses[i]];
            delete currentvoters[voterAddresses[i]];
        }
        while (voterAddresses.length > 0) {
            voterAddresses.pop();
        }
    }

    function registerProposal(string memory _name, address _candidateAddress) external onlyCommissioner onlyDuringElection {
        proposals.push(Proposal(_name, _candidateAddress));
        emit ProposalRegistered(keccak256(abi.encodePacked(_name)), _name);
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
    return getCandidates();
    }

    function getCandidates() internal view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](totalCandidates);
        for (uint256 i = 0; i < candidateAddress.length; i++) {
            // Compute candidate's bytes32 ID from the stored address
            bytes32 candId = keccak256(abi.encodePacked(candidateAddress[i]));
            candidateList[i] = candidates[candId];
        }
        return candidateList;
    }

    function getVoter(address _voterAddress) external view returns (Voter memory) {
        return currentvoters[_voterAddress];
    }

    /* Fallback & Receive */
    fallback() external {
        revert("This contract does not accept Ether.");
    }
}
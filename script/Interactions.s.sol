// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ElectionVoting} from "src/OnChainVoting.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

/**
 * @title   Interactions
 * @notice A contract to simplify user interactions with the ElectionVoting contract.
 *         It integrates configuration settings via HelperConfig and acts as a mediator
 *         for election-related actions.
 */

contract Interactions{
ElectionVoting public electionVoting;
    HelperConfig public helperConfig;

    constructor(address _electionVoting, address _helperConfig) {
        electionVoting = ElectionVoting(_electionVoting);
        helperConfig = HelperConfig(_helperConfig);
    }

    function startElection() external {
        require(msg.sender == electionVoting.electoralCommissioner(), "Not authorized");
        electionVoting.startElection();
    }

    function stopElection() external {
        require(msg.sender == electionVoting.electoralCommissioner(), "Not authorized");
        electionVoting.stopElection();
    }

    function addCandidate(address _candidate, string calldata _name) external {
        require(msg.sender == electionVoting.electoralCommissioner(), "Not authorized");
        electionVoting.addCandidate(_candidate, _name);
    }

    function vote(bytes32 _candidateId) external {
        electionVoting.vote(_candidateId);
    }

    function registerProposal(string calldata _name, address _candidateAddress) external {
        require(msg.sender == electionVoting.electoralCommissioner(), "Not authorized");
        electionVoting.registerProposal(_name, _candidateAddress);
    }

    function getProposals() external view returns (ElectionVoting.Proposal[] memory) {
        return electionVoting.getProposals();
    }

    function getVoter(address _voterAddress) external view returns (ElectionVoting.Voter memory) {
        return electionVoting.getVoter(_voterAddress);
    }

    function getNetworkConfig() external view returns (HelperConfig.NetworkConfig memory) {
        return helperConfig.getConfig();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {DeployOnChainVoting} from "script/DeployOnChainVoting.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ElectionVoting} from "src/OnChainVoting.sol";

contract OnChainVotingTest is Test {
    ElectionVoting public electionVoting;
    HelperConfig public helperConfig;

    // Define addresses
    address public electoralCommissioner = makeAddr("electoralCommissioner");
    address public candidateAddress = makeAddr("candidateAddress");
    address public voterAddress = makeAddr("voterAddress");
    address public nonElectoralCommissioner =
        makeAddr("nonElectoralCommissioner");

    uint256 public constant STARTING_ELECTORALCOMMISSIONER_BALANCE = 10 ether;
    uint256 public constant STARTING_VOTER_BALANCE = 1 ether;

    event OnChainVotingEntered(address indexed voterAddress);
    event WinnerPicked(address indexed winner);
    event ElectionResults(
        string winner,
        address indexed winnerAddress,
        uint256 totalVotes
    );

    function setUp() external {
        vm.prank(electoralCommissioner);
        electionVoting = new ElectionVoting();
        // Set up deployment with the intended electoralCommissioner.
        DeployOnChainVoting deployer = new DeployOnChainVoting();
        (electionVoting, helperConfig) = deployer.deployContractOnChainVoting();

        // HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // assertEq(
        //     config.startingVoterBalance,
        //     1 ether,
        //     "startingVoterBalance should be 1 ether"
        // );

        assertEq(
            electionVoting.electoralCommissioner(),
            electoralCommissioner,
            "Electoral Commissioner should match the address set in `vm.startPrank`"
        );

        // Deal funds individually.
        vm.deal(electoralCommissioner, STARTING_ELECTORALCOMMISSIONER_BALANCE);
        vm.deal(voterAddress, STARTING_VOTER_BALANCE);
        vm.deal(candidateAddress, STARTING_VOTER_BALANCE);
    }

    // Test that only the electoral commissioner can start the election.
    function testOnlyElectoralCommissionerCanStartElection() external {
        // The electoral commissioner is correctly set during deployment.
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        vm.stopPrank();

        // Verifing that the election is now active
        bool active = electionVoting.electionActive();
        assertTrue(active, "Election should be active after startElection");
    }

    // Test that adding a candidate works when called by the electoral commissioner. //
    function testSuccessfulAdditionOfCandidate() external {
        // Start the election first.
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        // Add a candidate.
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();
    }

    function testAddingAlreadyExistingCandidate() external {
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");

        // Attempt to add the same candidate should revert.
        vm.expectRevert(
            ElectionVoting.ElectionVoting_CandidateAlreadyExists.selector
        );
        electionVoting.addCandidate(candidateAddress, "Candidate 1");

        vm.stopPrank();
    }

    // Test voting functionality. //
    function testSuccessfulVoteByVoter() external {
        // Start election and add candidate by electoral commissioner.
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();

        // Cast vote from voterAddress.
        bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
        vm.prank(voterAddress);
        electionVoting.vote(candidateId);
    }

    function testDoubleVotingByVoter() external {
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();

        // Cast vote from voterAddress.
        bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
        vm.prank(voterAddress);
        electionVoting.vote(candidateId);

        // Attempt double-voting should revert.
        vm.prank(voterAddress);
        vm.expectRevert(
            ElectionVoting.ElectionVoting_VoterAlreadyVoted.selector
        );
        electionVoting.vote(candidateId);
    }

    // Test stopping the election.
    function testStopElection() external {
        // Start election and add candidate by electoral commissioner.
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();

        // Vote as voter.
        bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
        vm.prank(voterAddress);
        electionVoting.vote(candidateId);

        // Stop election as electoral commissioner.
        vm.prank(electoralCommissioner);
        electionVoting.stopElection();

        // After stopping, the election should be inactive.
        bool active = electionVoting.electionActive();
        assertFalse(active, "Election should be inactive after stopElection");

        // Checks that totals are reset.
        uint256 totalCandidates = electionVoting.totalCandidates();
        uint256 totalVoters = electionVoting.totalVoters();
        assertEq(totalCandidates, 0, "Candidates should be reset");
        assertEq(totalVoters, 0, "Voters should be reset");
    }

    function testOnlyCommissionerModifier() external {
        vm.prank(nonElectoralCommissioner);
        vm.expectRevert(ElectionVoting.ElectionVoting_NotAuthorized.selector);
        electionVoting.startElection();
    }

    function testOnlyWhenElectionInactiveModifier() external {
        // first election launch successful
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();

        // second election launch should revert
        vm.expectRevert(
            ElectionVoting.ElectionVoting_ElectionAlreadyActive.selector
        );
        electionVoting.startElection();
        vm.stopPrank();
    }

    function testOnlyDuringElectionModifier() external {
        vm.startPrank(electoralCommissioner);
        vm.expectRevert(
            ElectionVoting.ElectionVoting_ElectionNotActive.selector
        );
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();
    }

    function testRegisterProposal() external {
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.registerProposal("Proposal 1", candidateAddress);
        electionVoting.registerProposal("Proposal 2", candidateAddress);
        vm.stopPrank();

        ElectionVoting.Proposal[] memory proposals = electionVoting
            .getProposals();
        assertEq(
            proposals.length,
            2,
            "There should be two proposals registered"
        );
        // Verify proposal names:
        assertEq(
            keccak256(abi.encodePacked(proposals[0].name)),
            keccak256(abi.encodePacked("Proposal 1"))
        );
        assertEq(
            keccak256(abi.encodePacked(proposals[1].name)),
            keccak256(abi.encodePacked("Proposal 2"))
        );
    }

    function testGetCandidates() external {
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        address candidateAddress2 = makeAddr("candidateAddress2");
        electionVoting.addCandidate(candidateAddress2, "Candidate 2");
        vm.stopPrank();

        ElectionVoting.Candidate[] memory candidates = electionVoting
            .getAllCandidates();
        assertEq(candidates.length, 2, "There should be two candidates");
        assertEq(
            keccak256(abi.encodePacked(candidates[0].name)),
            keccak256(abi.encodePacked("Candidate 1"))
        );
        assertEq(
            keccak256(abi.encodePacked(candidates[1].name)),
            keccak256(abi.encodePacked("Candidate 2"))
        );
    }

    function testgetVoter() external {
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();

        bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
        vm.prank(voterAddress);
        electionVoting.vote(candidateId);

        ElectionVoting.Voter memory voterInfo = electionVoting.getVoter(
            voterAddress
        );
        assertEq(
            voterInfo.voterAddress,
            voterAddress,
            "The voter address should match"
        );
    }

    function testFallbackRevertsOnEtherTransfer() external {
        vm.expectRevert(bytes("This contract does not accept Ether."));
        (bool success, ) = address(electionVoting).call{value: 1 ether}("");
        assertTrue(!success, "Fallback has reverted on ether transfer");
    }

    function testEmitElectionResults() external {
        vm.startPrank(electoralCommissioner);
        electionVoting.startElection();
        electionVoting.addCandidate(candidateAddress, "Candidate 1");
        vm.stopPrank();

        bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
        vm.prank(voterAddress);
        electionVoting.vote(candidateId);

        // Expecting the event ElectionResults upon stopping the election.
        vm.startPrank(electoralCommissioner);
        vm.expectEmit(true, true, false, true);
        emit ElectionResults("Candidate 1", candidateAddress, 1);
        electionVoting.stopElection();
        vm.stopPrank();

        // Assert that totals are reset.
        assertEq(
            electionVoting.totalCandidates(),
            0,
            "Candidates should be reset"
        );
        assertEq(electionVoting.totalVoters(), 0, "Voters should be reset");
    }
}

// import {ElectionVoting} from "src/OnChainVoting.sol";
// import {Test, console2} from "forge-std/Test.sol";
// import {DeployOnChainVoting} from "script/DeployOnChainVoting.s.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";

// contract OnChainVotingTest is Test {
//     ElectionVoting public electionVoting;
//     HelperConfig public helperConfig;

//     address public electoralCommissioner = makeAddr("electoralCommissioner");
//     address public candidateAddress = makeAddr("candidateAddress");
//     address public secondCandidateAddress = makeAddr("secondCandidateAddress");
//     address public voterAddress = makeAddr("voterAddress");

//     uint256 public constant STARTING_ELECTORALCOMISSIONER_BALANCE = 10 ether;
//     uint256 public constant STARTING_VOTER_BALANCE = 1 ether;

//     event OnChainVotingEntered(address indexed voterAddress);
//     event WinnerPicked(address indexed winner);

//     function setUp() external {
//         // Deploy the ElectionVoting contract via deploy script.
//         DeployOnChainVoting deployer = new DeployOnChainVoting();
//         (electionVoting, helperConfig) = deployer.deployContractOnChainVoting();

//         // Retrieve Netowork configuration
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
//         assert(config.startingVoterBalance == 1 ether);

//         // Deal funds individually
//         vm.deal(electoralCommissioner, STARTING_ELECTORALCOMISSIONER_BALANCE);
//         vm.deal(voterAddress, STARTING_VOTER_BALANCE);
//     }

//     // Test that only the electoral commissioner can start the election.
//     function testOnlyElectoralCommissionerCanStartElection() external {
//         vm.prank(electoralCommissioner);
//         electionVoting.startElection();

//         bool active = electionVoting.electionActive();
//         assertTrue(active, "Election is active after startElection");
//     }

//     function testNetworkConfigStartingVoterBalance() external view {
//         // Retrieve network configuration from HelperConfig.
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
//         // Assert that the startingVoterBalance is 1 ether.
//         assertEq(
//             config.startingVoterBalance,
//             1 ether,
//             "startingVoterBalance should be 1 ether"
//         );
//     }

//     // Test that a candidate can be added and duplicate candidates are rejected.
//     function testAddCandidate() external {
//         // Start the election.
//         vm.prank(electoralCommissioner);
//         electionVoting.startElection();

//         // Add a candidate.
//         electionVoting.addCandidate(candidateAddress, "Candidate 1");

//         // Attempt to add the same candidate again, expecting a revert.
//         vm.expectRevert(
//             ElectionVoting.ElectionVoting_CandidateAlreadyExists.selector
//         );
//         electionVoting.addCandidate(candidateAddress, "Candidate 1");
//     }

//     // Test that a voter can cast a vote and cannot vote twice.
//     function testVote() external {
//         // Start the election and add a candidate.
//         vm.prank(electoralCommissioner);
//         vm.prank(voterAddress);
//         electionVoting.startElection();
//         vm.prank(electoralCommissioner);
//         electionVoting.addCandidate(candidateAddress, "Candidate 1");

//         // Voter votes for the candidate.
//         bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
//         electionVoting.vote(candidateId);

//         // Expect a revert if the same voter tries to vote again.
//         vm.expectRevert(ElectionVoting.ElectionVoting_AlreadyVoted.selector);
//         electionVoting.vote(candidateId);
//     }

//     // Test that stopping the election emits results and resets the election.
//     function testStopElection() external {
//         // Start the election, add a candidate, and cast a vote.
//         vm.prank(electoralCommissioner);
//         vm.prank(voterAddress);
//         electionVoting.startElection();
//         electionVoting.addCandidate(candidateAddress, "Candidate 1");
//         bytes32 candidateId = keccak256(abi.encodePacked(candidateAddress));
//         electionVoting.vote(candidateId);

//         // Stop the election.
//         electionVoting.stopElection();

//         // Assert the election is inactive.
//         bool active = electionVoting.electionActive();
//         assertFalse(active, "Election should be inactive after stopElection");

//         // Check that total candidates and voters are reset.
//         uint256 totalCandidates = electionVoting.totalCandidates();
//         uint256 totalVoters = electionVoting.totalVoters();
//         assertEq(totalCandidates, 0, "Candidates should be reset");
//         assertEq(totalVoters, 0, "Voters should be reset");
//     }
// }

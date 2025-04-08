// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ElectionVoting} from "src/OnChainVoting.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract DeployOnChainVoting is Script {
    function run() external returns (ElectionVoting) {
        (ElectionVoting electionVoting, ) = deployContractOnChainVoting();
        return electionVoting;
    }

    function deployContractOnChainVoting() public returns (ElectionVoting, HelperConfig) {
        address electoralCommissioner = makeAddr("electoralCommissioner"); // only for testing without Broadcast

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        assert(config.startingVoterBalance == 1 ether);

        vm.prank(electoralCommissioner);
        // vm.startBroadcast();
        // If ElectionVoting requires constructor arguments based on the configuration,
        // adjust the following call accordingly. For example:
        // ElectionVoting electionVoting = new ElectionVoting(config.startingVoterBalance, config.startingElectoralCommissionerBalance);
        ElectionVoting electionVoting = new ElectionVoting();
        // vm.stopBroadcast();

        return (electionVoting, helperConfig);
    }
}

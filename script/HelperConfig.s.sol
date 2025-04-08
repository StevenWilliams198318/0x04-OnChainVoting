// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 startingVoterBalance;
        uint256 startingElectoralCommissionerBalance;
    }

    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        // Initialize local configuration.
        networkConfigs[LOCAL_CHAIN_ID] = NetworkConfig({
            startingVoterBalance: 1 ether,
            startingElectoralCommissionerBalance: 10 ether
        });

        // Initialize Sepolia configuration.
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 _chainId
    ) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfigs[_chainId];
        if (config.startingVoterBalance != 0) {
            return config;
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                startingVoterBalance: 1 ether,
                startingElectoralCommissionerBalance: 10 ether
            });
    }
}

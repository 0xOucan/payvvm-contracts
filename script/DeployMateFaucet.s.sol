// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MateFaucet} from "@EVVM/testnet/contracts/services/MateFaucet.sol";

/**
 * @title DeployMateFaucet
 * @notice Deployment script for MATE Faucet EVVM service
 * @dev Deploys the faucet contract with predefined configuration
 *
 * Usage (with interactive wallet):
 * ./deploy-mate-faucet.sh
 *
 * Or manual:
 * forge script script/DeployMateFaucet.s.sol:DeployMateFaucet \
 *   --rpc-url $ETH_SEPOLIA_RPC_URL \
 *   --account monad-deployer \
 *   --broadcast \
 *   --via-ir \
 *   -vvvv
 */
contract DeployMateFaucet is Script {
    // ============ Configuration ============

    // EVVM contract address on Sepolia (from PAYVVM deployment)
    address constant EVVM_ADDRESS = 0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e;

    // MATE token address (EVVM principal token)
    address constant MATE_TOKEN = 0x0000000000000000000000000000000000000001;

    // Faucet owner address (admin who can withdraw and configure)
    address constant FAUCET_OWNER = 0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99;

    // Default claim amount: 510 MATE (MATE has 18 decimals)
    uint256 constant CLAIM_AMOUNT = 510 * 1e18; // 510 MATE

    // Default cooldown: 24 hours (86400 seconds)
    uint256 constant COOLDOWN_PERIOD = 24 hours;

    // ============ State ============

    MateFaucet public faucet;

    function setUp() public {}

    function run() public {
        console2.log("=== MATE Faucet Deployment ===");
        console2.log("EVVM Address:", EVVM_ADDRESS);
        console2.log("MATE Token:", MATE_TOKEN);
        console2.log("Faucet Owner:", FAUCET_OWNER);
        console2.log("Claim Amount:", CLAIM_AMOUNT, "(510 MATE)");
        console2.log("Cooldown Period:", COOLDOWN_PERIOD, "seconds (24 hours)");
        console2.log("Deployer:", msg.sender);

        vm.startBroadcast();

        // Deploy MateFaucet
        faucet = new MateFaucet(
            EVVM_ADDRESS,
            MATE_TOKEN,
            FAUCET_OWNER,
            CLAIM_AMOUNT,
            COOLDOWN_PERIOD
        );

        vm.stopBroadcast();

        console2.log("\n=== Deployment Successful ===");
        console2.log("MateFaucet Address:", address(faucet));
        console2.log("EVVM ID:", faucet.evvmId());
        console2.log("\n=== Next Steps ===");
        console2.log("1. Fund the faucet by sending MATE to faucet address:");
        console2.log("   - Use EVVM pay() to send MATE to faucet");
        console2.log("   - Faucet will accumulate MATE balance in EVVM");
        console2.log("");
        console2.log("2. Test claim functionality:");
        console2.log("   - Users sign claim message");
        console2.log("   - Fishers execute claim transactions");
        console2.log("");
        console2.log("3. Monitor faucet balance:");
        console2.log("   faucet.getFaucetBalance()");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {PyusdFaucet} from "@EVVM/testnet/contracts/services/PyusdFaucet.sol";

/**
 * @title DeployPyusdFaucet
 * @notice Deployment script for PYUSD Faucet EVVM service
 * @dev Deploys the faucet contract with predefined configuration
 *
 * Usage:
 * forge script script/DeployPyusdFaucet.s.sol:DeployPyusdFaucet \
 *   --rpc-url $ETH_SEPOLIA_RPC_URL \
 *   --broadcast \
 *   --via-ir \
 *   -vvvv
 */
contract DeployPyusdFaucet is Script {
    // ============ Configuration ============

    // EVVM contract address on Sepolia (from PAYVVM deployment)
    address constant EVVM_ADDRESS = 0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e;

    // PYUSD token address on Ethereum Sepolia
    address constant PYUSD_TOKEN = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9;

    // Faucet owner address (admin who can withdraw and configure)
    address constant FAUCET_OWNER = 0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99;

    // Default claim amount: 10 PYUSD (PYUSD has 6 decimals)
    uint256 constant CLAIM_AMOUNT = 10 * 1e6; // 10 PYUSD

    // Default cooldown: 24 hours (86400 seconds)
    uint256 constant COOLDOWN_PERIOD = 24 hours;

    // ============ State ============

    PyusdFaucet public faucet;

    function setUp() public {}

    function run() public {
        console2.log("=== PYUSD Faucet Deployment ===");
        console2.log("EVVM Address:", EVVM_ADDRESS);
        console2.log("PYUSD Token:", PYUSD_TOKEN);
        console2.log("Faucet Owner:", FAUCET_OWNER);
        console2.log("Claim Amount:", CLAIM_AMOUNT, "(10 PYUSD)");
        console2.log("Cooldown Period:", COOLDOWN_PERIOD, "seconds (24 hours)");
        console2.log("Deployer:", msg.sender);

        vm.startBroadcast();

        // Deploy PyusdFaucet
        faucet = new PyusdFaucet(
            EVVM_ADDRESS,
            PYUSD_TOKEN,
            FAUCET_OWNER,
            CLAIM_AMOUNT,
            COOLDOWN_PERIOD
        );

        vm.stopBroadcast();

        console2.log("\n=== Deployment Successful ===");
        console2.log("PyusdFaucet Address:", address(faucet));
        console2.log("EVVM ID:", faucet.evvmId());
        console2.log("\n=== Next Steps ===");
        console2.log("1. Fund the faucet by depositing PYUSD to EVVM:");
        console2.log("   - Transfer PYUSD to EVVM treasury contract");
        console2.log("   - Call treasury.deposit() with faucet address");
        console2.log("   OR");
        console2.log("   - Send PYUSD payments to faucet address via EVVM");
        console2.log("");
        console2.log("2. Test claim functionality:");
        console2.log("   - Users sign claim message");
        console2.log("   - Fishers execute claim transactions");
        console2.log("");
        console2.log("3. Monitor faucet balance:");
        console2.log("   faucet.getFaucetBalance()");
    }
}

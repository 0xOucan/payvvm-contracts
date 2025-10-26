#!/bin/bash

# MATE Faucet Verification Script
# Verifies the deployed MateFaucet contract on Etherscan

set -e  # Exit on error

# Load environment variables
source .env

CONTRACT_ADDRESS="0x068E9091e430786133439258C4BeeD696939405e"

echo "========================================="
echo "MATE Faucet Etherscan Verification"
echo "========================================="
echo ""
echo "Contract Address: $CONTRACT_ADDRESS"
echo "Network: Ethereum Sepolia"
echo ""

# Constructor arguments (ABI-encoded)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,address,uint256,uint256)" \
  "0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e" \
  "0x0000000000000000000000000000000000000001" \
  "0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99" \
  "510000000000000000000" \
  "86400")

echo "🔍 Verifying contract on Etherscan..."

# Verify contract on Etherscan
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 300 \
  --watch \
  --constructor-args "$CONSTRUCTOR_ARGS" \
  --verifier etherscan \
  --etherscan-api-key "$ETHERSCAN_API" \
  --compiler-version v0.8.30 \
  --via-ir \
  "$CONTRACT_ADDRESS" \
  src/contracts/services/MateFaucet.sol:MateFaucet

echo ""
echo "✅ Verification complete!"
echo "View on Etherscan: https://sepolia.etherscan.io/address/$CONTRACT_ADDRESS"
echo ""
echo "🎉 MATE Faucet verification complete!"

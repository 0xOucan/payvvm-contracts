#!/bin/bash

# PYUSD Faucet Verification Script
# Verifies the deployed PyusdFaucet contract on Etherscan

set -e  # Exit on error

# Load environment variables
source .env

CONTRACT_ADDRESS="0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a"

echo "========================================="
echo "PYUSD Faucet Etherscan Verification"
echo "========================================="
echo ""
echo "Contract Address: $CONTRACT_ADDRESS"
echo "Network: Ethereum Sepolia"
echo ""

# Constructor arguments (ABI-encoded)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,address,uint256,uint256)" \
  "0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e" \
  "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9" \
  "0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99" \
  "1000000" \
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
  src/contracts/services/PyusdFaucet.sol:PyusdFaucet

echo ""
echo "✅ Verification complete!"
echo "View on Etherscan: https://sepolia.etherscan.io/address/$CONTRACT_ADDRESS"
echo ""
echo "🎉 PYUSD Faucet verification complete!"

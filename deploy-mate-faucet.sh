#!/bin/bash

# MATE Faucet Deployment Script
# Uses interactive password prompt for monad-deployer wallet

set -e  # Exit on error

# Load environment variables
source .env

echo "========================================="
echo "MATE Faucet Deployment & Verification"
echo "========================================="
echo ""
echo "Network: Ethereum Sepolia"
echo "Wallet: monad-deployer"
echo ""

# Run deployment with interactive wallet
echo "📝 Deploying contract..."
forge script script/DeployMateFaucet.s.sol:DeployMateFaucet \
  --rpc-url https://sepolia.gateway.tenderly.co \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer 2>/dev/null || echo "0x0") \
  --broadcast \
  --via-ir \
  -vvvv

# Extract deployed contract address from broadcast file
BROADCAST_FILE="broadcast/DeployMateFaucet.s.sol/11155111/run-latest.json"

if [ -f "$BROADCAST_FILE" ]; then
  # Extract contract address using grep and sed (no jq required)
  CONTRACT_ADDRESS=$(grep -o '"contractAddress":"0x[a-fA-F0-9]\{40\}"' "$BROADCAST_FILE" | head -1 | sed 's/"contractAddress":"//;s/"//')

  if [ -n "$CONTRACT_ADDRESS" ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo "Contract Address: $CONTRACT_ADDRESS"
    echo ""
    echo "🔍 Verifying contract on Etherscan..."

    # Constructor arguments (ABI-encoded)
    # MateFaucet(address _evvm, address _mateToken, address _owner, uint256 _claimAmount, uint256 _cooldownPeriod)
    CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address,address,uint256,uint256)" \
      "0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e" \
      "0x0000000000000000000000000000000000000001" \
      "0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99" \
      "510000000000000000000" \
      "86400")

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
  else
    echo "❌ Could not extract contract address from broadcast file"
    exit 1
  fi
else
  echo "❌ Broadcast file not found: $BROADCAST_FILE"
  exit 1
fi

echo ""
echo "🎉 MATE Faucet deployment and verification complete!"

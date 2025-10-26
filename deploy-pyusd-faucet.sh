#!/bin/bash

# PYUSD Faucet Deployment Script
# Uses interactive password prompt for monad-deployer wallet

echo "========================================="
echo "PYUSD Faucet Deployment"
echo "========================================="
echo ""
echo "Network: Ethereum Sepolia"
echo "Wallet: monad-deployer"
echo ""

# Run deployment with interactive wallet
forge script script/DeployPyusdFaucet.s.sol:DeployPyusdFaucet \
  --rpc-url https://sepolia.gateway.tenderly.co \
  --account monad-deployer \
  --sender $(cast wallet address --account monad-deployer 2>/dev/null || echo "0x0") \
  --broadcast \
  --via-ir \
  -vvvv

echo ""
echo "Deployment complete!"

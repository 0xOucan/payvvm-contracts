#!/bin/bash

# PAYVVM Contract Verification Script
# This uses Forge's built-in verification from broadcast files
# Run this 15-30 minutes after deployment

set -e

source .env

echo "========================================="
echo "PAYVVM Contract Verification"
echo "Using Forge Script Resume"
echo "========================================="
echo ""

# Check if broadcast file exists
BROADCAST_FILE="broadcast/DeployTestnet.s.sol/11155111/run-latest.json"
if [ ! -f "$BROADCAST_FILE" ]; then
    echo "Error: Broadcast file not found: $BROADCAST_FILE"
    echo "Please ensure you've deployed the contracts first."
    exit 1
fi

echo "Found broadcast file: $BROADCAST_FILE"
echo ""

# Get contract addresses from broadcast
STAKING=$(grep -A 3 '"contractName": "Staking"' $BROADCAST_FILE | grep '"contractAddress"' | cut -d'"' -f4)
EVVM=$(grep -A 3 '"contractName": "Evvm"' $BROADCAST_FILE | grep '"contractAddress"' | cut -d'"' -f4)
TREASURY=$(grep -A 3 '"contractName": "Treasury"' $BROADCAST_FILE | grep '"contractAddress"' | cut -d'"' -f4)
ESTIMATOR=$(grep -A 3 '"contractName": "Estimator"' $BROADCAST_FILE | grep '"contractAddress"' | cut -d'"' -f4)
NAMESERVICE=$(grep -A 3 '"contractName": "NameService"' $BROADCAST_FILE | grep '"contractAddress"' | cut -d'"' -f4)

echo "Contracts to verify:"
echo "  Staking:     $STAKING"
echo "  Evvm:        $EVVM"
echo "  Treasury:    $TREASURY"
echo "  Estimator:   $ESTIMATOR"
echo "  NameService: $NAMESERVICE"
echo ""

# Check if contracts are indexed on Etherscan
echo "Checking if contracts are indexed on Etherscan..."
sleep 2

CONTRACT_INDEXED=$(curl -s "https://api-sepolia.etherscan.io/api?module=proxy&action=eth_getCode&address=$STAKING&apikey=$ETHERSCAN_API" | grep -o '"result":"0x[0-9a-f]\{10,\}"' | wc -l)

if [ "$CONTRACT_INDEXED" -eq "0" ]; then
    echo ""
    echo "⚠️  WARNING: Contracts don't appear to be fully indexed on Etherscan yet."
    echo "   This usually takes 10-30 minutes after deployment."
    echo ""
    echo "   Current time: $(date)"
    echo "   You can:"
    echo "   1. Wait 10-15 more minutes and run this script again"
    echo "   2. Continue anyway (verification will likely fail)"
    echo ""
    read -p "Continue with verification? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Run this script again later."
        exit 0
    fi
else
    echo "✅ Contracts appear to be indexed on Etherscan"
fi

echo ""
echo "Starting verification using forge script --verify --resume..."
echo "This will use the exact deployment configuration from the broadcast file."
echo ""

# Use forge script with --verify and --resume to automatically verify all contracts
# This reads from the broadcast file and uses the same compilation settings
# Must include --account to match the original deployment
forge script script/DeployTestnet.s.sol:DeployTestnet \
    --rpc-url $RPC_URL_ETH_SEPOLIA \
    --account monad-deployer \
    --verify \
    --etherscan-api-key $ETHERSCAN_API \
    --resume \
    -vvv

VERIFY_RESULT=$?

echo ""
echo "========================================="
if [ $VERIFY_RESULT -eq 0 ]; then
    echo "✅ Verification completed successfully!"
else
    echo "⚠️  Verification completed with some errors."
    echo ""
    echo "Common causes:"
    echo "1. Contracts still being indexed (wait longer)"
    echo "2. Already verified"
    echo "3. Etherscan rate limiting"
fi
echo "========================================="
echo ""
echo "Check your contracts on Etherscan:"
echo "Staking:     https://sepolia.etherscan.io/address/$STAKING#code"
echo "Evvm:        https://sepolia.etherscan.io/address/$EVVM#code"
echo "Estimator:   https://sepolia.etherscan.io/address/$ESTIMATOR#code"
echo "NameService: https://sepolia.etherscan.io/address/$NAMESERVICE#code"
echo "Treasury:    https://sepolia.etherscan.io/address/$TREASURY#code"
echo ""

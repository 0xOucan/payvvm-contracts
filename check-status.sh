#!/bin/bash

# PAYVVM Status Checker
# Displays current status of your PAYVVM deployment

set -e

source .env 2>/dev/null || true

echo "========================================="
echo "PAYVVM Deployment Status"
echo "========================================="
echo ""

# Contract addresses
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
STAKING="0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816"
ESTIMATOR="0x5dB7cDb7601f9ABCfc5089D66b1A3525471bf2aB"
NAMESERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
TREASURY="0x3D6cB29a1F97a2CFf7a48af96F7ED3A02F6aA38E"
REGISTRY="0x389dC8fb09211bbDA841D59f4a51160dA2377832"

RPC="${RPC_URL_ETH_SEPOLIA:-https://0xrpc.io/sep}"

echo "📍 Network: Ethereum Sepolia (Chain ID: 11155111)"
echo ""

# Check registry registration
echo "🔍 Checking Registry Status..."
IS_REGISTERED=$(cast call $REGISTRY "isAddressRegistered(uint256,address)(bool)" 11155111 $EVVM --rpc-url $RPC 2>/dev/null || echo "false")

if [ "$IS_REGISTERED" = "true" ]; then
    echo "✅ Registered in EVVM Registry"

    # Get EVVM ID
    METADATA=$(cast call $REGISTRY "getEvvmIdMetadata(uint256)((uint256,address))" 1000 --rpc-url $RPC 2>/dev/null)
    REGISTERED_ADDRESS=$(echo "$METADATA" | grep -o "0x[a-fA-F0-9]\{40\}")

    if [ "${REGISTERED_ADDRESS,,}" = "${EVVM,,}" ]; then
        echo "   EVVM ID: 1000"
        echo "   View: https://www.evvm.info/evvms/1000"
    fi
else
    echo "❌ Not registered in EVVM Registry"
fi

echo ""
echo "📝 Deployed Contracts:"
echo ""

# Check each contract
check_contract() {
    local name=$1
    local address=$2

    # Try to get code at address
    CODE=$(cast code $address --rpc-url $RPC 2>/dev/null || echo "0x")

    if [ "$CODE" != "0x" ] && [ ${#CODE} -gt 10 ]; then
        echo "✅ $name"
        echo "   $address"
        echo "   https://sepolia.etherscan.io/address/$address#code"
    else
        echo "❌ $name - NOT DEPLOYED"
        echo "   $address"
    fi
    echo ""
}

check_contract "EVVM         " $EVVM
check_contract "Staking      " $STAKING
check_contract "Estimator    " $ESTIMATOR
check_contract "NameService  " $NAMESERVICE
check_contract "Treasury     " $TREASURY

echo "========================================="
echo ""
echo "📖 For full details, see: DEPLOYMENT_SUMMARY.md"
echo ""

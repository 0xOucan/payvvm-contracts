#!/bin/bash

# PAYVVM EVVM Registry Registration Script
# Registers your deployed EVVM in the official registry

set -e

source .env

echo "========================================="
echo "PAYVVM Registry Registration"
echo "========================================="
echo ""

# Registry contract address (Ethereum Sepolia)
REGISTRY="0x389dC8fb09211bbDA841D59f4a51160dA2377832"

# Your deployed EVVM address on Sepolia
EVVM_ADDRESS="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"

# Chain ID for Ethereum Sepolia
CHAIN_ID=11155111

echo "Registry Contract: $REGISTRY"
echo "EVVM Address: $EVVM_ADDRESS"
echo "Chain ID: $CHAIN_ID"
echo ""

# Check current registration status
echo "Checking if EVVM is already registered..."
IS_REGISTERED=$(cast call $REGISTRY "isAddressRegistered(uint256,address)(bool)" $CHAIN_ID $EVVM_ADDRESS --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null || echo "false")

if [ "$IS_REGISTERED" = "true" ]; then
    echo ""
    echo "⚠️  This EVVM is already registered!"

    # Try to find the EVVM ID
    PUBLIC_IDS=$(cast call $REGISTRY "getPublicEvvmIdActive()(uint256[])" --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null)
    if [ -n "$PUBLIC_IDS" ]; then
        # Extract first ID from array (simplified - assumes your EVVM is in the list)
        FOUND_ID=$(echo "$PUBLIC_IDS" | grep -o "[0-9]\+" | head -1)
        if [ -n "$FOUND_ID" ]; then
            echo "   EVVM ID: $FOUND_ID"
            echo "   View on registry: https://www.evvm.info/evvms/$FOUND_ID"
        fi
    fi

    echo ""
    read -p "Do you want to continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo "✓ EVVM is not yet registered"
fi

echo ""
echo "📝 IMPORTANT: ID Assignment"
echo "   - IDs are AUTO-ASSIGNED starting from 1000"
echo "   - You CANNOT choose a specific ID like 9981"
echo "   - You will receive the next available ID"
echo ""

read -p "Ready to register? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Registration cancelled."
    exit 0
fi

echo ""
echo "Registering EVVM in the registry..."
echo "Using keystore account: monad-deployer"
echo ""

# Call registerEvvm function
# This will auto-assign an ID and return it
echo "Executing registration transaction..."
echo "You will be prompted to enter your keystore password..."
echo ""

CAST_OUTPUT=$(cast send $REGISTRY \
    "registerEvvm(uint256,address)" \
    $CHAIN_ID \
    $EVVM_ADDRESS \
    --rpc-url $RPC_URL_ETH_SEPOLIA \
    --account monad-deployer 2>&1)

# Extract transaction hash from output
TX_HASH=$(echo "$CAST_OUTPUT" | grep -i "transactionHash" | grep -o "0x[a-fA-F0-9]\{64\}" | head -1)

# If not found, try alternative format (some cast versions output differently)
if [ -z "$TX_HASH" ]; then
    TX_HASH=$(echo "$CAST_OUTPUT" | grep -o "0x[a-fA-F0-9]\{64\}" | head -1)
fi

if [ -z "$TX_HASH" ]; then
    echo "❌ Registration failed or could not extract transaction hash!"
    echo "Output: $CAST_OUTPUT"
    exit 1
fi

echo ""
echo "✅ Registration transaction sent!"
echo "   Transaction hash: $TX_HASH"
echo "   View on Etherscan: https://sepolia.etherscan.io/tx/$TX_HASH"
echo ""
echo "Waiting for transaction confirmation..."

# Wait for transaction to be mined
cast receipt $TX_HASH --rpc-url $RPC_URL_ETH_SEPOLIA --confirmations 1 > /dev/null 2>&1

echo ""
echo "Transaction confirmed!"
echo ""
echo "Fetching your assigned EVVM ID..."

# Get all public EVVM IDs
PUBLIC_IDS=$(cast call $REGISTRY "getPublicEvvmIdActive()(uint256[])" --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null)

# Extract the last/highest ID (most recently registered)
ASSIGNED_ID_DEC=$(echo "$PUBLIC_IDS" | grep -o "[0-9]\+" | tail -1)

# Verify it's our EVVM by checking metadata
if [ -n "$ASSIGNED_ID_DEC" ]; then
    METADATA=$(cast call $REGISTRY "getEvvmIdMetadata(uint256)((uint256,address))" $ASSIGNED_ID_DEC --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null)
    REGISTERED_ADDRESS=$(echo "$METADATA" | grep -o "0x[a-fA-F0-9]\{40\}")

    if [ "${REGISTERED_ADDRESS,,}" != "${EVVM_ADDRESS,,}" ]; then
        echo "Warning: Could not verify EVVM ID. Please check manually."
    fi
fi

echo ""
echo "========================================="
echo "✅ REGISTRATION SUCCESSFUL!"
echo "========================================="
echo ""
echo "Your PAYVVM has been registered!"
echo ""
echo "📋 Registration Details:"
if [ -n "$ASSIGNED_ID_DEC" ]; then
    echo "   EVVM ID: $ASSIGNED_ID_DEC"
    echo "   Chain: Ethereum Sepolia ($CHAIN_ID)"
    echo "   Contract: $EVVM_ADDRESS"
    echo ""
    echo "🔗 View Your EVVM:"
    echo "   Registry: https://www.evvm.info/evvms/$ASSIGNED_ID_DEC"
    echo "   Etherscan: https://sepolia.etherscan.io/address/$EVVM_ADDRESS"
else
    echo "   Chain: Ethereum Sepolia ($CHAIN_ID)"
    echo "   Contract: $EVVM_ADDRESS"
    echo ""
    echo "⚠️  Could not automatically retrieve EVVM ID."
    echo "   Check the registry manually at: https://www.evvm.info"
    echo "   Your contract: https://sepolia.etherscan.io/address/$EVVM_ADDRESS"
fi
echo ""
echo "🎉 Your PAYVVM is now discoverable by all EVVM services!"
echo ""

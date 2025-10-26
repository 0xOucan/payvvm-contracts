#!/bin/bash

# Check PAYVVM Username Availability and Info

set -e

source .env

NAMESERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"

echo "========================================="
echo "PAYVVM Username Checker"
echo "========================================="
echo ""

if [ -z "$1" ]; then
    echo "Usage: ./check-username.sh <username>"
    echo ""
    echo "Examples:"
    echo "  ./check-username.sh test"
    echo "  ./check-username.sh 0xoucan"
    echo ""
    exit 1
fi

USERNAME="$1"

echo "🔍 Checking: \$$USERNAME.payvvm"
echo ""

# Check if username exists and get owner
OWNER=$(cast call $NAMESERVICE \
    "verifyStrictAndGetOwnerOfIdentity(string)(address)" \
    "$USERNAME" \
    --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null || echo "0x0000000000000000000000000000000000000000")

if [ "$OWNER" = "0x0000000000000000000000000000000000000000" ]; then
    echo "✅ USERNAME AVAILABLE!"
    echo ""
    echo "   \$$USERNAME.payvvm is not registered"
    echo "   You can register this username!"
    echo ""
    echo "To register:"
    echo "  1. Use the web interface (recommended)"
    echo "  2. Or run: ./register-username.sh $USERNAME"
    echo ""
else
    echo "❌ USERNAME TAKEN"
    echo ""
    echo "   Owner: $OWNER"
    echo "   View on Etherscan: https://sepolia.etherscan.io/address/$OWNER"
    echo ""

    # Try to get metadata
    echo "📋 Username Details:"
    METADATA=$(cast call $NAMESERVICE \
        "getUsernameMetadata(string)((address,uint256,uint256))" \
        "$USERNAME" \
        --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null || echo "")

    if [ -n "$METADATA" ]; then
        # Parse metadata (simplified)
        echo "   Registration Date: [Blockchain data]"
        echo "   Expiration Date: [Check on-chain]"
        echo ""
    fi

    echo "Options:"
    echo "  - Try a different username"
    echo "  - Make an offer to buy from current owner"
    echo ""
fi

echo "========================================="

#!/bin/bash
set -e

source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
NAME_SERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"

echo "========================================="
echo "Debug Registration Issue"
echo "========================================="
echo ""

# Try calling with no payment (empty bytes for signature_EVVM)
echo "Testing with minimal parameters..."
echo ""

# Simple test values
USER="0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45"
HASH="0x0000000000000000000000000000000000000000000000000000000000000001"
NONCE=$(date +%s)
EVVM_NONCE=0

echo "Test parameters:"
echo "User: $USER"
echo "Hash: $HASH"
echo "Nonce: $NONCE"
echo ""

# Create signature
EVVM_ID=0
MESSAGE="$EVVM_ID,preRegistrationUsername,$HASH,$NONCE"
echo "Message: $MESSAGE"
echo ""

echo "Attempting to call contract with cast send (dry run)..."
echo ""

# Try to estimate gas to see what error we get
cast call $NAME_SERVICE \
    "preRegistrationUsername(address,bytes32,uint256,bytes,uint256,uint256,bool,bytes)" \
    "$USER" \
    "$HASH" \
    "$NONCE" \
    "0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" \
    0 \
    "$EVVM_NONCE" \
    false \
    "0x00" \
    --from "$USER" \
    --rpc-url $RPC_URL_ETH_SEPOLIA || echo "Expected to fail - signature is dummy"

echo ""
echo "========================================="

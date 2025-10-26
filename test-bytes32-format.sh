#!/bin/bash

# Test to verify the exact format of bytes32ToString
source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"

# Test hash
TEST_HASH="0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

echo "Testing bytes32ToString format..."
echo "Input: $TEST_HASH"
echo ""

# Call the AdvancedStrings library function
RESULT=$(cast call 0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e "bytes32ToString(bytes32)(string)" "$TEST_HASH" --rpc-url $RPC_URL_ETH_SEPOLIA)

echo "Contract output: $RESULT"
echo ""

# Check if it's lowercase
if [[ "$RESULT" =~ ^0x[0-9a-f]{64}$ ]]; then
    echo "✅ Format is lowercase hex with 0x prefix"
else
    echo "Format: $RESULT"
fi

#!/bin/bash

source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
NAME_SERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
YOUR_ADDRESS="0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45"

echo "=== Signature Diagnosis ==="
echo ""

# Test values
USERNAME="test"
SECRET="1234567890"
COMBINED="${USERNAME}${SECRET}"

# Generate hash
HASH=$(printf "%s" "$COMBINED" | cast keccak)
echo "1. Hash: $HASH"

# Get EVVM ID
EVVM_ID=$(cast call $EVVM "getEvvmID()(uint256)" --rpc-url $RPC_URL_ETH_SEPOLIA)
echo "2. EVVM ID: $EVVM_ID"

# Generate nonce
NONCE=$(date +%s%N | head -c 15)
echo "3. Nonce: $NONCE"

# Construct message
MESSAGE="${EVVM_ID},preRegistrationUsername,${HASH},${NONCE}"
echo "4. Message: $MESSAGE"
echo ""

# Calculate EIP-191 prefix
MSG_LENGTH=${#MESSAGE}
PREFIX="\x19Ethereum Signed Message:\n${MSG_LENGTH}"
echo "5. EIP-191 Prefix: \\x19Ethereum Signed Message:\\n${MSG_LENGTH}"
echo "6. Full message length: $MSG_LENGTH characters"
echo ""

# Show what we're signing
echo "7. Full EIP-191 message:"
echo "   Prefix: \\x19Ethereum Signed Message:\\n${MSG_LENGTH}"
echo "   Message: $MESSAGE"
echo ""

# Try to get wallet address
WALLET_ADDR=$(cast wallet address monad-deployer 2>/dev/null || echo "Unable to get address without password")
echo "8. Wallet address: $WALLET_ADDR"
echo "9. Expected signer: $YOUR_ADDRESS"

if [ "$WALLET_ADDR" != "Unable to get address without password" ]; then
    if [ "$WALLET_ADDR" = "$YOUR_ADDRESS" ]; then
        echo "   ✅ Wallet address matches YOUR_ADDRESS"
    else
        echo "   ❌ WARNING: Wallet address doesn't match YOUR_ADDRESS!"
        echo "   This could be the issue!"
    fi
fi


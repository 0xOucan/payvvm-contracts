#!/bin/bash
set -e
source .env

# Test parameters
EVVM_ID=0
HASH="0xc9758e584bad0b06282239f3ea987ac0ab40dd66714bf46087d4ce35f894faad"
NONCE=176102314683936
USER="0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45"

# Build message exactly as Solidity does
MESSAGE="${EVVM_ID},preRegistrationUsername,${HASH},${NONCE}"

echo "========================================="
echo "Testing Exact Signature Format"
echo "========================================="
echo ""
echo "Message: $MESSAGE"
echo "Message length: ${#MESSAGE}"
echo ""

# What Solidity does:
# 1. message = "0,preRegistrationUsername,0x...,176102314683936"
# 2. messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message))
# 3. ecrecover(messageHash, v, r, s)

# What cast wallet sign does:
# - Automatically adds "\x19Ethereum Signed Message:\n{length}" prefix
# - Then signs

echo "Signing with cast wallet sign..."
SIGNATURE=$(cast wallet sign --account monad-deployer "$MESSAGE")
echo "Signature: $SIGNATURE"
echo ""

# Verify locally
echo "Verifying signature..."
RECOVERED=$(cast wallet verify "$MESSAGE" "$SIGNATURE" --address "$USER" 2>&1 || echo "FAILED")
if echo "$RECOVERED" | grep -q "FAILED"; then
    echo "❌ Local verification FAILED"
else
    echo "✅ Local verification PASSED"
fi
echo ""

# Now let's test if the contract can verify it
echo "Testing contract verification..."
echo ""

# Create minimal call to just test signature verification
# We'll use a simple test - try calling with our real signature
NAME_SERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"

echo "Attempting contract call..."
cast call $NAME_SERVICE \
    "preRegistrationUsername(address,bytes32,uint256,bytes,uint256,uint256,bool,bytes)" \
    "$USER" \
    "$HASH" \
    "$NONCE" \
    "$SIGNATURE" \
    0 \
    0 \
    false \
    "0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" \
    --from "$USER" \
    --rpc-url $RPC_URL_ETH_SEPOLIA 2>&1 | head -20

echo ""
echo "========================================="

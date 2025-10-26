#!/bin/bash

source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
YOUR_ADDRESS="0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45"

# Test values
USERNAME="test"
SECRET="1234567890"
COMBINED="${USERNAME}${SECRET}"

# Generate hash (both methods)
BASH_HASH=$(printf "%s" "$COMBINED" | cast keccak)
echo "Hash: $BASH_HASH"

# Get EVVM ID
EVVM_ID=$(cast call $EVVM "getEvvmID()(uint256)" --rpc-url $RPC_URL_ETH_SEPOLIA)
echo "EVVM ID: $EVVM_ID"

# Generate nonce
NS_NONCE=$(date +%s%N | head -c 15)
echo "Nonce: $NS_NONCE"

# Construct message - EXACT format contract expects
MESSAGE="${EVVM_ID},preRegistrationUsername,${BASH_HASH},${NS_NONCE}"

echo ""
echo "Message to sign:"
echo "$MESSAGE"
echo ""
echo "Message breakdown:"
echo "  EVVM_ID: $EVVM_ID"
echo "  Function: preRegistrationUsername"
echo "  Hash: $BASH_HASH"
echo "  Nonce: $NS_NONCE"
echo ""
echo "Hash is lowercase: $(echo $BASH_HASH | grep -q '^0x[0-9a-f]*$' && echo 'YES ✅' || echo 'NO ❌')"
echo "Hash has 0x prefix: $(echo $BASH_HASH | grep -q '^0x' && echo 'YES ✅' || echo 'NO ❌')"
echo "Hash length: ${#BASH_HASH} chars (should be 66: 0x + 64 hex chars)"

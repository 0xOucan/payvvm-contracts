#!/bin/bash

# Simplified test without interactive input
# We'll use cast to test signature recovery

source .env

echo "=== Testing Signature Generation and Recovery ==="
echo ""

# Known test values
USERNAME="test"
SECRET="1234567890"
COMBINED="${USERNAME}${SECRET}"

# Generate hash
HASH=$(printf "%s" "$COMBINED" | cast keccak)
echo "1. Hash: $HASH"

# Create message
EVVM_ID="0"
NONCE="176102314683936"  # Fixed nonce for testing
MESSAGE="${EVVM_ID},preRegistrationUsername,${HASH},${NONCE}"
echo "2. Message: $MESSAGE"
echo "3. Message length: ${#MESSAGE}"
echo ""

# Sign with cast (using keystore)
echo "4. Attempting to sign with cast..."
SIG=$(printf "%s" "$MESSAGE" | cast wallet sign --from monad-deployer 2>&1)

if echo "$SIG" | grep -q "0x"; then
    echo "   Signature: $SIG"
    echo ""
    
    # Try to verify the signature
    echo "5. Attempting to recover signer..."
    # Note: cast doesn't have a built-in verify command, so we'll use viem for this
    
else
    echo "   ❌ Failed to sign: $SIG"
fi


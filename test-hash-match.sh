#!/bin/bash

USERNAME="test"
SECRET="1234567890"
COMBINED="${USERNAME}${SECRET}"

echo "Testing hash generation..."
echo "Combined: $COMBINED"
echo ""

echo "Bash/Cast method:"
BASH_HASH=$(printf "%s" "$COMBINED" | cast keccak)
echo "  Hash: $BASH_HASH"
echo ""

echo "Viem method:"
VIEM_HASH=$(node -e "const { keccak256, stringToHex } = require('viem'); console.log(keccak256(stringToHex('${COMBINED}')));")
echo "  Hash: $VIEM_HASH"
echo ""

if [ "$BASH_HASH" = "$VIEM_HASH" ]; then
    echo "✅ MATCH! Both methods produce the same hash"
else
    echo "❌ MISMATCH! Hashes are different"
fi

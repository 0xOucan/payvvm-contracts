#!/bin/bash

# Direct PAYVVM Username Pre-Registration
# Attempts to register directly without fisher signatures

set -e

source .env

NAMESERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"

echo "========================================="
echo "Direct Username Pre-Registration"
echo "========================================="
echo ""

if [ -z "$1" ]; then
    echo "Usage: ./direct-register.sh <username> [secret]"
    echo "Example: ./direct-register.sh test"
    exit 1
fi

USERNAME="$1"
SECRET="${2:-$(date +%s%N | cut -b1-10)}"

echo "📝 Details:"
echo "   Username: $USERNAME (displays as: \$$USERNAME.payvvm)"
echo "   Secret: $SECRET"
echo ""

# Validate
if ! echo "$USERNAME" | grep -qE '^[a-z0-9_]{3,20}$'; then
    echo "❌ Invalid username"
    exit 1
fi

# Check availability
OWNER=$(cast call $NAMESERVICE \
    "verifyStrictAndGetOwnerOfIdentity(string)(address)" \
    "$USERNAME" \
    --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null || echo "0x0000000000000000000000000000000000000000")

if [ "$OWNER" != "0x0000000000000000000000000000000000000000" ]; then
    echo "❌ Username taken by: $OWNER"
    exit 1
fi

echo "✅ Available!"
echo ""

# Get address
YOUR_ADDRESS=$(cast wallet address --account monad-deployer)
echo "👤 Your address: $YOUR_ADDRESS"
echo ""

# Calculate hash
HASH=$(cast keccak "${USERNAME}${SECRET}")
echo "🔐 Commitment hash: $HASH"
echo ""

# Generate nonce (using timestamp)
NONCE=$(date +%s%N | cut -b1-13)
echo "📊 Nonce: $NONCE"
echo ""

# Save info
SAVE_FILE="/tmp/payvvm_reg_${USERNAME}.json"
cat > $SAVE_FILE <<EOF
{
  "username": "$USERNAME",
  "secret": "$SECRET",
  "hash": "$HASH",
  "nonce": "$NONCE",
  "address": "$YOUR_ADDRESS",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "💾 Saved: $SAVE_FILE"
echo ""

echo "⚠️  SIGNATURE REQUIREMENT:"
echo ""
echo "The NameService contract requires an EIP-191 signature to verify"
echo "that YOU authorize this registration."
echo ""
echo "Message format:"
echo "  'preRegisterUsername,<address>,<hash>,<nonce>'"
echo ""

# Generate the message to sign
FUNCTION_ID="preRegisterUsername"
MESSAGE="${FUNCTION_ID},${YOUR_ADDRESS},${HASH},${NONCE}"

echo "📝 Message to sign:"
echo "   $MESSAGE"
echo ""

echo "🔐 Generating signature..."
echo "   You'll be prompted for your keystore password..."
echo ""

# Sign the message with cast
SIGNATURE=$(cast wallet sign "$MESSAGE" --account monad-deployer)

if [ -z "$SIGNATURE" ]; then
    echo "❌ Signature generation failed"
    exit 1
fi

echo "✅ Signature generated:"
echo "   $SIGNATURE"
echo ""

read -p "Proceed with pre-registration? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled. Info saved in $SAVE_FILE"
    exit 0
fi

echo ""
echo "🚀 Submitting pre-registration transaction..."
echo ""

# Call preRegistrationUsername
# Note: This might fail if the signature format doesn't match exactly what the contract expects
# The contract may expect a different message format or hashing scheme

cast send $NAMESERVICE \
    "preRegistrationUsername(address,bytes32,uint256,bytes,uint256)" \
    $YOUR_ADDRESS \
    $HASH \
    $NONCE \
    $SIGNATURE \
    0 \
    --account monad-deployer \
    --rpc-url $RPC_URL_ETH_SEPOLIA

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✅ PRE-REGISTRATION SUBMITTED!"
    echo "========================================="
    echo ""
    echo "⏰ NEXT STEPS:"
    echo ""
    echo "1. WAIT 30 MINUTES MINIMUM"
    echo ""
    echo "2. After 30 minutes, complete registration:"
    echo "   (This is complex - use web interface recommended)"
    echo ""
    echo "3. Or wait for web interface to be ready:"
    echo "   cd envioftpayvvm && yarn start"
    echo ""
    echo "Your registration info: $SAVE_FILE"
    echo ""
else
    echo ""
    echo "========================================="
    echo "❌ PRE-REGISTRATION FAILED"
    echo "========================================="
    echo ""
    echo "Possible reasons:"
    echo "  - Signature format doesn't match contract expectation"
    echo "  - Need to pay 500 MATE upfront (requires EVVM payment signature too)"
    echo "  - Nonce already used"
    echo ""
    echo "RECOMMENDATION:"
    echo "  Use the web interface for reliable registration:"
    echo "  1. cd /home/oucan/PayVVM/envioftpayvvm"
    echo "  2. yarn start"
    echo "  3. Register via UI at http://localhost:3000"
    echo ""
    echo "The UI handles all signature complexity automatically!"
    echo ""
fi

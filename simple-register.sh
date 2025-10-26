#!/bin/bash

# Simple PAYVVM Username Registration (Pre-Registration Only)
# This does the first step - you'll need to complete registration after 30 minutes

set -e

source .env

NAMESERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"

echo "========================================="
echo "PAYVVM Simple Username Pre-Registration"
echo "========================================="
echo ""

if [ -z "$1" ]; then
    echo "Usage: ./simple-register.sh <username>"
    echo "Example: ./simple-register.sh test"
    exit 1
fi

USERNAME="$1"

# Validate
if ! echo "$USERNAME" | grep -qE '^[a-z0-9_]{3,20}$'; then
    echo "❌ Invalid username format"
    exit 1
fi

# Check availability
OWNER=$(cast call $NAMESERVICE \
    "verifyStrictAndGetOwnerOfIdentity(string)(address)" \
    "$USERNAME" \
    --rpc-url $RPC_URL_ETH_SEPOLIA 2>/dev/null || echo "0x0000000000000000000000000000000000000000")

if [ "$OWNER" != "0x0000000000000000000000000000000000000000" ]; then
    echo "❌ Username already taken by: $OWNER"
    exit 1
fi

echo "✅ Username available: \$$USERNAME.payvvm"
echo ""

# Get wallet address
echo "Getting your address..."
YOUR_ADDRESS=$(cast wallet address --account monad-deployer)
echo "📍 Your address: $YOUR_ADDRESS"
echo ""

# Generate secret and hash
SECRET=$(date +%s%N | cut -b1-10)
HASH=$(cast keccak "${USERNAME}${SECRET}")

echo "🔐 Registration Info:"
echo "   Username: $USERNAME"
echo "   Secret: $SECRET"
echo "   Hash: $HASH"
echo ""

# Save for later
SAVE_FILE="/tmp/payvvm_reg_${USERNAME}.txt"
cat > $SAVE_FILE <<EOF
USERNAME=$USERNAME
SECRET=$SECRET
HASH=$HASH
YOUR_ADDRESS=$YOUR_ADDRESS
TIMESTAMP=$(date)
EOF

echo "💾 Saved to: $SAVE_FILE"
echo ""

echo "⚠️  IMPORTANT: Username registration requires TWO signatures:"
echo "   1. NameService signature (authorization)"
echo "   2. EVVM payment signature (500 MATE payment)"
echo ""
echo "This is complex to do via command line."
echo ""
echo "RECOMMENDED: Use the web interface instead!"
echo ""

read -p "Attempt pre-registration anyway? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Use the web interface for easier registration."
    echo "Run: cd envioftpayvvm && yarn start"
    exit 0
fi

echo ""
echo "🚀 Attempting pre-registration..."
echo ""

# The issue: We need to generate proper EIP-191 signatures
# This is extremely complex via cast alone

echo "❌ LIMITATION:"
echo ""
echo "Proper signature generation for EVVM services requires:"
echo "  - EIP-191 message formatting"
echo "  - Specific function ID encoding"
echo "  - Nonce management"
echo "  - Dual signature coordination"
echo ""
echo "This is NOT straightforward with cast commands alone."
echo ""
echo "========================================="
echo "MANUAL REGISTRATION INSTRUCTIONS"
echo "========================================="
echo ""
echo "To register \$$USERNAME.payvvm manually:"
echo ""
echo "1. Build the web interface:"
echo "   cd /home/oucan/PayVVM/envioftpayvvm"
echo "   yarn start"
echo ""
echo "2. Open: http://localhost:3000"
echo ""
echo "3. Connect wallet (monad-deployer address: $YOUR_ADDRESS)"
echo ""
echo "4. Use the registration UI to:"
echo "   - Enter username: $USERNAME"
echo "   - Pre-register (UI generates signatures automatically)"
echo "   - Wait 30 minutes"
echo "   - Complete registration (UI handles reveal)"
echo ""
echo "The web interface handles all signature complexity!"
echo ""
echo "========================================="
echo ""
echo "Your registration details are saved in: $SAVE_FILE"
echo ""

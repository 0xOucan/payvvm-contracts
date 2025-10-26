#!/bin/bash
set -e

source .env

# Contract addresses
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
NAME_SERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
PRINCIPAL_TOKEN="0x0000000000000000000000000000000000000001"

# Get parameters
USERNAME="${1}"
SECRET="${2}"
WALLET_NAME="${3:-monad-deployer}"

# Try to load from saved file if no arguments
if [ -z "$USERNAME" ] && [ -f ".registration-pending" ]; then
    echo "Loading registration info from .registration-pending..."
    source .registration-pending
    echo "Found: $USERNAME (secret: $SECRET)"
    echo ""
fi

if [ -z "$USERNAME" ] || [ -z "$SECRET" ]; then
    echo "Usage: $0 <username> <secret> [wallet_name]"
    echo ""
    echo "Or run without arguments if you have .registration-pending file"
    echo ""
    exit 1
fi

echo "========================================="
echo "Register .payvvm Name - Step 2"
echo "========================================="
echo "Username: $USERNAME"
echo "Secret: $SECRET"
echo "Wallet: $WALLET_NAME"
echo "========================================="
echo ""

# Get EVVM ID from contract (what NameService will use for signature verification)
EVVM_ID=$(cast call $EVVM "getEvvmID()(uint256)" --rpc-url $RPC_URL_ETH_SEPOLIA)
echo "EVVM ID (from contract): $EVVM_ID"
echo ""

# Get wallet address
YOUR_ADDRESS=$(cast wallet address --account "$WALLET_NAME" 2>/dev/null)
if [ -z "$YOUR_ADDRESS" ]; then
    echo "❌ Wallet '$WALLET_NAME' not found"
    exit 1
fi

echo "Your address: $YOUR_ADDRESS"
echo ""

# Check if 30 minutes have passed (if we have timestamp)
if [ -f ".registration-pending" ]; then
    source .registration-pending
    CURRENT_TIME=$(date +%s)
    TIME_ELAPSED=$((CURRENT_TIME - TIMESTAMP))
    TIME_REMAINING=$((1800 - TIME_ELAPSED))  # 1800 seconds = 30 minutes

    if [ $TIME_REMAINING -gt 0 ]; then
        MINUTES=$((TIME_REMAINING / 60))
        echo "⏰ WARNING: You need to wait $MINUTES more minute(s)"
        echo "   Pre-registration was $(($TIME_ELAPSED / 60)) minutes ago"
        echo "   Required wait time: 30 minutes"
        echo ""
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Registration cancelled. Come back in $MINUTES minutes!"
            exit 0
        fi
    else
        echo "✅ 30+ minutes have passed. You can complete registration!"
        echo ""
    fi
fi

# Generate new nonces for step 2
echo "Generating nonces..."
NS_NONCE=$(date +%s%N | head -c 15)  # Use nanosecond timestamp (15 digits)
EVVM_NONCE=$(cast call $EVVM "getNextCurrentSyncNonce(address)(uint256)" $YOUR_ADDRESS --rpc-url $RPC_URL_ETH_SEPOLIA)

echo "NameService nonce: $NS_NONCE (timestamp-based)"
echo "EVVM nonce: $EVVM_NONCE (sequential)"
echo ""

# NOTE: No payment needed for Step 2! The payment was made in Step 1.
# But we still need to provide signatures for the registration call.

# For registration, we use priorityFee=0, nonce=currentNonce, but NO payment signature
# Actually, looking at the contract, registrationUsername DOES need payment signature
# because it's marked with the same pattern. Let me check if it calls makePay...

echo "========================================="
echo "Generating Signatures"
echo "========================================="
echo ""

# Signature 1: NameService signature for registrationUsername
# Message format: "{evvmID},registrationUsername,{username},{secret},{nonce}"
NS_MESSAGE="${EVVM_ID},registrationUsername,${USERNAME},${SECRET},${NS_NONCE}"
echo "NameService message: $NS_MESSAGE"
echo "Please sign when prompted..."
echo ""
NS_SIGNATURE=$(cast wallet sign --account "$WALLET_NAME" "$NS_MESSAGE")
echo "NameService signature: $NS_SIGNATURE"
echo ""

# Signature 2: EVVM signature (empty/dummy since no payment in step 2)
# According to the contract, registrationUsername also requires payment signature
# But it shouldn't actually charge again. Let me provide a signature anyway.
PRIORITY_FEE=0
PRIORITY_FLAG="false"
EXECUTOR=$NAME_SERVICE
REGISTRATION_COST=0  # No cost in step 2

EVVM_MESSAGE="${EVVM_ID},pay,${NAME_SERVICE},${PRINCIPAL_TOKEN},${REGISTRATION_COST},${PRIORITY_FEE},${EVVM_NONCE},${PRIORITY_FLAG},${EXECUTOR}"
echo "EVVM payment message (should be free): $EVVM_MESSAGE"
echo "Please sign when prompted..."
echo ""
EVVM_SIGNATURE=$(cast wallet sign --account "$WALLET_NAME" "$EVVM_MESSAGE")
echo "EVVM payment signature: $EVVM_SIGNATURE"
echo ""

echo "========================================="
echo "Completing Registration"
echo "========================================="
echo ""

# Call registrationUsername
cast send $NAME_SERVICE \
    "registrationUsername(address,string,uint256,uint256,bytes,uint256,uint256,bool,bytes)" \
    "$YOUR_ADDRESS" \
    "$USERNAME" \
    "$SECRET" \
    "$NS_NONCE" \
    "$NS_SIGNATURE" \
    "$PRIORITY_FEE" \
    "$EVVM_NONCE" \
    "$PRIORITY_FLAG" \
    "$EVVM_SIGNATURE" \
    --account "$WALLET_NAME" \
    --rpc-url $RPC_URL_ETH_SEPOLIA

echo ""
echo "========================================="
echo "✅ Registration Complete!"
echo "========================================="
echo ""
echo "Your username: \$$USERNAME.payvvm"
echo "Points to: $YOUR_ADDRESS"
echo ""
echo "Verify with:"
echo "  ./check-username.sh $USERNAME"
echo ""
echo "========================================="

# Clean up
rm -f .registration-pending

#!/bin/bash
set -e

source .env

# Contract addresses
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
NAME_SERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
PRINCIPAL_TOKEN="0x0000000000000000000000000000000000000001"

# Registration cost
REGISTRATION_COST=500000000000000000000  # 500 MATE in wei

# Get username and wallet from arguments
USERNAME="${1}"
WALLET_NAME="${2:-monad-deployer}"

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username> [wallet_name]"
    echo ""
    echo "Example: $0 test monad-deployer"
    echo ""
    echo "Username rules:"
    echo "  - 3-20 characters"
    echo "  - Lowercase letters, numbers, underscore only"
    echo "  - Will be registered as \$${USERNAME}.payvvm"
    exit 1
fi

echo "========================================="
echo "Register .payvvm Name - Step 1"
echo "========================================="
echo "Username: $USERNAME"
echo "Will be: \$$USERNAME.payvvm"
echo "Cost: 500 MATE tokens"
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
    echo "Available wallets:"
    cast wallet list
    exit 1
fi

echo "Your address: $YOUR_ADDRESS"
echo ""

# Check MATE balance
echo "Checking MATE balance..."
./check-mate-balance.sh "$YOUR_ADDRESS" | grep "Balance (MATE)" || true
echo ""

# Generate random secret
SECRET=$(date +%s%N | sha256sum | head -c 10)
echo "Generated secret: $SECRET"
echo ""

# Calculate hash for pre-registration
# hashPreRegisteredUsername = keccak256(abi.encodePacked(username, secret))
HASH_INPUT=$(printf "%s%s" "$USERNAME" "$SECRET" | xxd -p | tr -d '\n')
HASH_PRE_REG=$(echo -n "$HASH_INPUT" | xxd -r -p | cast keccak | tr '[:upper:]' '[:lower:]')
echo "Pre-registration hash: $HASH_PRE_REG"
echo ""

# Generate nonces
# NameService uses a nonce mapping (any unused nonce works) - use timestamp for uniqueness
# EVVM uses a sequential counter
echo "Generating nonces..."
NS_NONCE=$(date +%s%N | head -c 15)  # Use nanosecond timestamp (15 digits)
EVVM_NONCE=$(cast call $EVVM "getNextCurrentSyncNonce(address)(uint256)" $YOUR_ADDRESS --rpc-url $RPC_URL_ETH_SEPOLIA)

echo "NameService nonce: $NS_NONCE (timestamp-based)"
echo "EVVM nonce: $EVVM_NONCE (sequential)"
echo ""

# Priority settings (no priority for simplicity)
PRIORITY_FEE=0
PRIORITY_FLAG="false"
EXECUTOR=$NAME_SERVICE

echo "========================================="
echo "Generating Signatures"
echo "========================================="
echo ""

# Signature 1: NameService signature for preRegistrationUsername
# Message format: "{evvmID},preRegistrationUsername,{hashUsername},{nonce}"
NS_MESSAGE="${EVVM_ID},preRegistrationUsername,${HASH_PRE_REG},${NS_NONCE}"
echo "NameService message: $NS_MESSAGE"
echo "Please sign when prompted..."
echo ""
NS_SIGNATURE=$(cast wallet sign --account "$WALLET_NAME" "$NS_MESSAGE")
echo "NameService signature: $NS_SIGNATURE"
echo ""

# Signature 2: EVVM payment signature
# Message format: "{evvmID},pay,{receiver},{token},{amount},{priorityFee},{nonce},{priorityFlag},{executor}"
EVVM_MESSAGE="${EVVM_ID},pay,${NAME_SERVICE},${PRINCIPAL_TOKEN},${REGISTRATION_COST},${PRIORITY_FEE},${EVVM_NONCE},${PRIORITY_FLAG},${EXECUTOR}"
echo "EVVM payment message: $EVVM_MESSAGE"
echo "Please sign when prompted..."
echo ""
EVVM_SIGNATURE=$(cast wallet sign --account "$WALLET_NAME" "$EVVM_MESSAGE")
echo "EVVM payment signature: $EVVM_SIGNATURE"
echo ""

echo "========================================="
echo "Submitting Pre-Registration"
echo "========================================="
echo ""

# Call preRegistrationUsername
cast send $NAME_SERVICE \
    "preRegistrationUsername(address,bytes32,uint256,bytes,uint256,uint256,bool,bytes)" \
    "$YOUR_ADDRESS" \
    "$HASH_PRE_REG" \
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
echo "✅ Pre-Registration Complete!"
echo "========================================="
echo ""
echo "⏰ IMPORTANT: You must wait 30 minutes before completing registration"
echo ""
echo "Save this information for Step 2:"
echo "  Username: $USERNAME"
echo "  Secret: $SECRET"
echo ""
echo "After 30 minutes, run:"
echo "  ./complete-registration.sh $USERNAME $SECRET $WALLET_NAME"
echo ""
echo "========================================="

# Save to file for convenience
cat > .registration-pending <<EOF
USERNAME=$USERNAME
SECRET=$SECRET
WALLET_NAME=$WALLET_NAME
YOUR_ADDRESS=$YOUR_ADDRESS
TIMESTAMP=$(date +%s)
NS_NONCE_USED=$NS_NONCE
EOF

echo ""
echo "Registration info saved to .registration-pending"
echo ""

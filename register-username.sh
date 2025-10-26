#!/bin/bash
set -e

# Load environment variables
source .env

# Contract addresses
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
NAME_SERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
PRINCIPAL_TOKEN="0x0000000000000000000000000000000000000001"

# EVVM metadata
EVVM_NAME="PayVVM"
COST=500

# Username to register
USERNAME="${1:-Blockchain_builder}"
WALLET_NAME="${2:-monad-deployer}"

echo "========================================="
echo "Register Username on PayVVM"
echo "========================================="
echo "Username: $USERNAME"
echo "Cost: $COST MATE tokens"
echo "Wallet: $WALLET_NAME"
echo "========================================="
echo ""

# Get wallet address
OWNER=$(cast wallet address --account "$WALLET_NAME")
echo "Owner address: $OWNER"

# Check MATE balance
BALANCE=$(cast call $EVVM "balanceOf(address,address)(uint256)" \
    $OWNER \
    $PRINCIPAL_TOKEN \
    --rpc-url $RPC_URL_ETH_SEPOLIA)

BALANCE_DEC=$((BALANCE))
echo "Current MATE balance: $BALANCE_DEC"

if [ "$BALANCE_DEC" -lt "$COST" ]; then
    echo ""
    echo "ERROR: Insufficient MATE tokens!"
    echo "You need $COST MATE but only have $BALANCE_DEC"
    echo ""
    echo "To get MATE tokens, run:"
    echo "  cast send $EVVM \"recalculateReward()\" --account $WALLET_NAME --rpc-url \$RPC_URL_ETH_SEPOLIA"
    echo ""
    echo "This will give you a random bonus of 5-25,415 MATE tokens!"
    exit 1
fi

# Get current nonce for the owner
NONCE=$(cast call $NAME_SERVICE "nonce(address)(uint256)" $OWNER --rpc-url $RPC_URL_ETH_SEPOLIA)
echo "Current nonce: $NONCE"
echo ""

# Generate signature using cast
# The EIP-191 message format is:
# 0x19 0x01 <domainSeparator> <structHash>
# Where:
# - domainSeparator = keccak256(abi.encodePacked("nameService", keccak256(bytes(EVVM_NAME))))
# - structHash = keccak256(abi.encode(typeHash, owner, keccak256(bytes(username)), cost, nonce))

echo "Generating EIP-191 signature..."
echo ""

# Calculate nameHash = keccak256(bytes(EVVM_NAME))
NAME_HASH=$(cast keccak "$(printf '%s' "$EVVM_NAME" | xxd -p)")
echo "nameHash: $NAME_HASH"

# Calculate domainSeparator = keccak256(abi.encodePacked("nameService", nameHash))
DOMAIN_DATA="$(printf 'nameService' | xxd -p)${NAME_HASH:2}"
DOMAIN_SEPARATOR=$(echo -n "$DOMAIN_DATA" | xxd -r -p | cast keccak)
echo "domainSeparator: $DOMAIN_SEPARATOR"

# Calculate typeHash = keccak256("registerName(address owner,string username,uint256 cost,uint256 nonce)")
TYPE_HASH=$(cast keccak "registerName(address owner,string username,uint256 cost,uint256 nonce)")
echo "typeHash: $TYPE_HASH"

# Calculate usernameHash = keccak256(bytes(username))
USERNAME_HASH=$(cast keccak "$(printf '%s' "$USERNAME" | xxd -p)")
echo "usernameHash: $USERNAME_HASH"

# Calculate structHash = keccak256(abi.encode(typeHash, owner, usernameHash, cost, nonce))
# abi.encode pads everything to 32 bytes
STRUCT_HASH=$(cast keccak "$(cast abi-encode 'f(bytes32,address,bytes32,uint256,uint256)' \
    "$TYPE_HASH" \
    "$OWNER" \
    "$USERNAME_HASH" \
    "$COST" \
    "$NONCE")")
echo "structHash: $STRUCT_HASH"

# Calculate final message hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash))
MESSAGE_HASH_DATA="1901${DOMAIN_SEPARATOR:2}${STRUCT_HASH:2}"
MESSAGE_HASH=$(echo -n "$MESSAGE_HASH_DATA" | xxd -r -p | cast keccak)
echo "messageHash: $MESSAGE_HASH"
echo ""

# Sign the message hash
echo "Please sign the message hash when prompted..."
SIGNATURE=$(cast wallet sign --account "$WALLET_NAME" --data "$MESSAGE_HASH" --no-hash)
echo "Signature: $SIGNATURE"
echo ""

# Submit the transaction
echo "Submitting registration transaction..."
echo ""

cast send $NAME_SERVICE \
    "registerName(address,string,uint256,uint256,bytes)" \
    "$OWNER" \
    "$USERNAME" \
    "$COST" \
    "$NONCE" \
    "$SIGNATURE" \
    --account "$WALLET_NAME" \
    --rpc-url $RPC_URL_ETH_SEPOLIA

echo ""
echo "========================================="
echo "Registration complete!"
echo "========================================="
echo ""
echo "Verify with:"
echo "cast call $NAME_SERVICE \"getUsername(address)(string)\" $OWNER --rpc-url \$RPC_URL_ETH_SEPOLIA"

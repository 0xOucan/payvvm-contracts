#!/bin/bash
set -e

source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
PRINCIPAL_TOKEN="0x0000000000000000000000000000000000000001"

USER_ADDRESS="${1:-0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45}"

echo "========================================="
echo "Check MATE Balance via Storage Reading"
echo "========================================="
echo ""
echo "User: $USER_ADDRESS"
echo "Token: $PRINCIPAL_TOKEN (MATE)"
echo ""

# Calculate storage slot for balances[user][token]
# balances is at slot 23 (counting through EvvmStorage.sol)
# For nested mapping: keccak256(abi.encode(token, keccak256(abi.encode(user, slot))))

echo "Calculating storage slot..."
echo ""

# Step 1: Calculate keccak256(abi.encode(user, 23))
INNER_SLOT=$(cast keccak "$(cast abi-encode 'f(address,uint256)' "$USER_ADDRESS" 23)")
echo "Inner slot hash: $INNER_SLOT"

# Step 2: Calculate keccak256(abi.encode(token, innerSlot))
FINAL_SLOT=$(cast keccak "$(cast abi-encode 'f(address,bytes32)' "$PRINCIPAL_TOKEN" "$INNER_SLOT")")
echo "Final storage slot: $FINAL_SLOT"
echo ""

# Read the storage slot
echo "Reading balance from storage..."
BALANCE_HEX=$(cast storage $EVVM $FINAL_SLOT --rpc-url $RPC_URL_ETH_SEPOLIA)
echo "Raw balance (hex): $BALANCE_HEX"

# Convert to decimal using cast (handles large numbers correctly)
BALANCE_DEC=$(cast to-dec $BALANCE_HEX)
echo "Balance (wei): $BALANCE_DEC"

# Convert to human-readable (18 decimals)
if [ "$BALANCE_DEC" != "0" ]; then
    BALANCE_READABLE=$(echo "scale=6; $BALANCE_DEC / 1000000000000000000" | bc)
    echo "Balance (MATE): $BALANCE_READABLE"
else
    echo "Balance (MATE): 0"
fi

echo ""
echo "========================================="

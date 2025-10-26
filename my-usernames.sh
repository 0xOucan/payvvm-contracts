#!/bin/bash

# List all usernames owned by an address

set -e

source .env

NAMESERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"

echo "========================================="
echo "My PAYVVM Usernames"
echo "========================================="
echo ""

# Get address from monad-deployer or use provided address
if [ -z "$1" ]; then
    ADDRESS=$(cast wallet address --account monad-deployer 2>/dev/null || echo "")
    if [ -z "$ADDRESS" ]; then
        echo "Usage: ./my-usernames.sh <address>"
        echo ""
        echo "Or configure monad-deployer wallet to check your own usernames"
        exit 1
    fi
    echo "📍 Checking usernames for: $ADDRESS (monad-deployer)"
else
    ADDRESS="$1"
    echo "📍 Checking usernames for: $ADDRESS"
fi

echo ""

# Note: To get all usernames owned by an address, we need to:
# 1. Query events from the NameService contract
# 2. Or use an indexer (Envio)

echo "⚠️  To see all owned usernames, you need:"
echo ""
echo "1. Use the Envio indexer (recommended):"
echo "   cd /home/oucan/PayVVM/envioftpayvvm/packages/envio"
echo "   pnpm codegen && pnpm dev"
echo "   Then query the indexed data"
echo ""
echo "2. Or use the web interface:"
echo "   cd /home/oucan/PayVVM/envioftpayvvm"
echo "   yarn start"
echo "   Connect wallet and view your dashboard"
echo ""
echo "3. Or query events manually:"
echo "   cast logs \\"
echo "     --from-block 9455841 \\"
echo "     --address $NAMESERVICE \\"
echo "     --rpc-url $RPC_URL_ETH_SEPOLIA \\"
echo "     'UsernameRegistered(address indexed,string,uint256)'"
echo ""

echo "========================================="
echo ""
echo "💡 TIP: The web interface is the easiest way to:"
echo "   - View all your usernames"
echo "   - Check expiration dates"
echo "   - Manage metadata"
echo "   - Renew usernames"
echo ""

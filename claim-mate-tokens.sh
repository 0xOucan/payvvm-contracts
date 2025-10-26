#!/bin/bash
set -e

source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"

WALLET_NAME="${1:-monad-deployer}"

echo "========================================="
echo "Claim MATE Tokens via recalculateReward()"
echo "========================================="
echo ""

# Get wallet address
YOUR_ADDRESS=$(cast wallet address --account "$WALLET_NAME" 2>/dev/null)
if [ -z "$YOUR_ADDRESS" ]; then
    echo "❌ Wallet '$WALLET_NAME' not found"
    echo "Available wallets:"
    cast wallet list
    exit 1
fi

echo "💼 Using wallet: $WALLET_NAME"
echo "📍 Address: $YOUR_ADDRESS"
echo ""

echo "🎰 About to call recalculateReward()..."
echo "   Reward formula: 2.5 MATE × random(1-5083)"
echo "   Expected reward: 2.5 to 12,707.5 MATE tokens!"
echo "   (More than enough for username registration: 500 MATE)"
echo ""

read -p "Claim MATE tokens? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo ""
echo "🚀 Calling recalculateReward()..."
echo ""

# Call the function - capture the transaction output
cast send $EVVM \
    "recalculateReward()" \
    --account "$WALLET_NAME" \
    --rpc-url $RPC_URL_ETH_SEPOLIA

echo ""
echo "========================================="
echo "✅ Check Transaction Status Above"
echo "========================================="
echo ""
echo "⚠️  NOTE: The EVVM contract has no balanceOf() or getBalance()"
echo "   function, so we cannot display your exact MATE balance."
echo ""
echo "   However, if the transaction shows 'status: 1 (success)',"
echo "   you now have MATE tokens in your EVVM balance!"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. RECOMMENDED: Use the web interface for username registration"
echo "   cd ../envioftpayvvm"
echo "   yarn install && yarn start"
echo "   Then visit http://localhost:3000"
echo ""
echo "2. Read the detailed analysis:"
echo "   cat USERNAME_REGISTRATION_ANALYSIS.md"
echo ""
echo "3. The CLI registration requires dual signatures (complex)"
echo "   See USERNAME_REGISTRATION_ANALYSIS.md for details"
echo ""

#!/bin/bash

# Get MATE tokens by depositing ETH and staking
# This script helps the admin get initial MATE tokens for PAYVVM operations

set -e

source .env

TREASURY="0x3D6cB29a1F97a2CFf7a48af96F7ED3A02F6aA38E"
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
STAKING="0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816"
PRINCIPAL_TOKEN="0x0000000000000000000000000000000000000001"

echo "========================================="
echo "PAYVVM MATE Token Acquisition"
echo "========================================="
echo ""
echo "MATE tokens are earned through staking and transaction rewards."
echo "This script will help you deposit ETH and stake to earn MATE."
echo ""

# Check which wallet to use
WALLET="${1:-monad-deployer}"

if [ -z "$WALLET" ]; then
    echo "Usage: ./get-mate-tokens.sh [wallet-name] [eth-amount]"
    echo "Example: ./get-mate-tokens.sh payvvm-admin 0.1"
    exit 1
fi

ETH_AMOUNT="${2:-0.01}"

echo "💼 Wallet: $WALLET"
echo "💰 ETH Amount: $ETH_AMOUNT ETH"
echo ""

# Get wallet address
YOUR_ADDRESS=$(cast wallet address --account $WALLET 2>/dev/null)
if [ -z "$YOUR_ADDRESS" ]; then
    echo "❌ Wallet '$WALLET' not found"
    echo "Available wallets:"
    cast wallet list
    exit 1
fi

echo "📍 Your address: $YOUR_ADDRESS"
echo ""

# Check current ETH balance
ETH_BALANCE=$(cast balance $YOUR_ADDRESS --rpc-url $RPC_URL_ETH_SEPOLIA --ether)
echo "💵 Current ETH balance: $ETH_BALANCE ETH"
echo ""

# Check current EVVM balances
echo "📊 Current EVVM balances:"
ETH_EVVM_BALANCE=$(cast call $EVVM "getBalance(address,address)(uint256)" $YOUR_ADDRESS "0x0000000000000000000000000000000000000000" --rpc-url $RPC_URL_ETH_SEPOLIA)
MATE_BALANCE=$(cast call $EVVM "getBalance(address,address)(uint256)" $YOUR_ADDRESS $PRINCIPAL_TOKEN --rpc-url $RPC_URL_ETH_SEPOLIA)

echo "   ETH in EVVM: $(cast --to-unit $ETH_EVVM_BALANCE ether) ETH"
echo "   MATE tokens: $(cast --to-unit $MATE_BALANCE ether) MATE"
echo ""

echo "========================================="
echo "OPTION 1: Deposit ETH to Treasury"
echo "========================================="
echo ""
echo "This will convert your ETH into EVVM balance."
echo "You can then use it for payments within PAYVVM."
echo ""
echo "Command:"
echo "  cast send $TREASURY \\"
echo "    'deposit(address,uint256)' \\"
echo "    0x0000000000000000000000000000000000000000 \\"
echo "    \$(cast --to-wei $ETH_AMOUNT ether) \\"
echo "    --value \$(cast --to-wei $ETH_AMOUNT ether) \\"
echo "    --account $WALLET \\"
echo "    --rpc-url $RPC_URL_ETH_SEPOLIA"
echo ""

read -p "Deposit $ETH_AMOUNT ETH to Treasury? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Depositing ETH to Treasury..."
    
    cast send $TREASURY \
        "deposit(address,uint256)" \
        0x0000000000000000000000000000000000000000 \
        $(cast --to-wei $ETH_AMOUNT ether) \
        --value $(cast --to-wei $ETH_AMOUNT ether) \
        --account $WALLET \
        --rpc-url $RPC_URL_ETH_SEPOLIA
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ ETH deposited successfully!"
        echo ""
        
        # Check new balance
        NEW_ETH_EVVM_BALANCE=$(cast call $EVVM "getBalance(address,address)(uint256)" $YOUR_ADDRESS "0x0000000000000000000000000000000000000000" --rpc-url $RPC_URL_ETH_SEPOLIA)
        echo "📊 New ETH balance in EVVM: $(cast --to-unit $NEW_ETH_EVVM_BALANCE ether) ETH"
    else
        echo "❌ Deposit failed"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "OPTION 2: Earn MATE through Staking"
echo "========================================="
echo ""
echo "⚠️  Important:"
echo "- MATE tokens are earned as rewards for staking"
echo "- Current reward: 5 MATE per qualifying transaction"
echo "- Golden Fisher has special staking privileges"
echo ""
echo "To stake and earn MATE, you need to:"
echo "1. Have ETH balance in EVVM (from Option 1)"
echo "2. Use the Staking contract to stake tokens"
echo "3. Process transactions to earn rewards"
echo ""
echo "Next steps:"
echo "- Review staking documentation: https://www.evvm.info/docs/Staking"
echo "- Use staking functions based on your role"
echo "- For Golden Fisher: Use goldenStaking() function"
echo ""

echo "========================================="
echo "OPTION 3: Process Transactions for Rewards"
echo "========================================="
echo ""
echo "Stakers earn 5 MATE per transaction they process."
echo ""
echo "To earn MATE through transaction processing:"
echo "1. Become a staker (stake tokens in Staking contract)"
echo "2. Process payments using payStaker functions"
echo "3. Receive 5 MATE rewards automatically"
echo ""

echo ""
echo "📋 Summary:"
echo "   ETH in EVVM: $(cast --to-unit $NEW_ETH_EVVM_BALANCE ether 2>/dev/null || echo $ETH_EVVM_BALANCE) ETH"
echo "   MATE tokens: $(cast --to-unit $MATE_BALANCE ether) MATE"
echo ""
echo "💡 To get MATE tokens for username registration (500 MATE),"
echo "   you need to stake and process ~100 transactions (5 MATE each)"
echo "   OR use Golden Fisher privileges for special access."
echo ""

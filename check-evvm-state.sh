#!/bin/bash
set -e

source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"

echo "========================================="
echo "EVVM Contract State Check"
echo "========================================="
echo ""

echo "Fetching EVVM metadata from storage..."
echo ""

# Storage layout from EvvmStorage.sol:
# Slot 0-9: Various addresses and configs
# Slot 10: evvmMetadata starts
# Within evvmMetadata struct:
#   Slot 10: EvvmName (string - length)
#   Slot 11: EvvmID (uint256)
#   Slot 12: principalTokenName (string - length)
#   Slot 13: principalTokenSymbol (string - length)
#   Slot 14: principalTokenAddress (address)
#   Slot 15: totalSupply (uint256)
#   Slot 16: eraTokens (uint256)
#   Slot 17: reward (uint256)

# Reading slot 15 for totalSupply
TOTAL_SUPPLY_HEX=$(cast storage $EVVM 15 --rpc-url $RPC_URL_ETH_SEPOLIA)
TOTAL_SUPPLY=$(cast to-dec $TOTAL_SUPPLY_HEX)

# Reading slot 16 for eraTokens
ERA_TOKENS_HEX=$(cast storage $EVVM 16 --rpc-url $RPC_URL_ETH_SEPOLIA)
ERA_TOKENS=$(cast to-dec $ERA_TOKENS_HEX)

# Reading slot 17 for reward
REWARD_HEX=$(cast storage $EVVM 17 --rpc-url $RPC_URL_ETH_SEPOLIA)
REWARD=$(cast to-dec $REWARD_HEX)

echo "Total Supply (wei): $TOTAL_SUPPLY"
TOTAL_SUPPLY_READABLE=$(echo "scale=2; $TOTAL_SUPPLY / 1000000000000000000" | bc)
echo "Total Supply: $TOTAL_SUPPLY_READABLE tokens"
echo ""

echo "Era Tokens (wei): $ERA_TOKENS"
ERA_TOKENS_READABLE=$(echo "scale=2; $ERA_TOKENS / 1000000000000000000" | bc)
echo "Era Tokens: $ERA_TOKENS_READABLE tokens"
echo ""

echo "Current Reward (wei): $REWARD"
REWARD_READABLE=$(echo "scale=6; $REWARD / 1000000000000000000" | bc)
echo "Current Reward: $REWARD_READABLE MATE per call"
echo ""

# Calculate if recalculateReward will work
echo "========================================="
echo "recalculateReward() Status"
echo "========================================="
echo ""

# Compare using bc for large numbers
IS_GREATER=$(echo "$TOTAL_SUPPLY > $ERA_TOKENS" | bc)
if [ "$IS_GREATER" -eq 1 ]; then
    echo "✅ Status: CAN CLAIM"
    echo ""

    # Calculate difference using bc for large numbers
    DIFFERENCE=$(echo "$TOTAL_SUPPLY - $ERA_TOKENS" | bc)
    DIFFERENCE_READABLE=$(echo "scale=2; $DIFFERENCE / 1000000000000000000" | bc)
    echo "Remaining claimable pool: $DIFFERENCE_READABLE tokens"
    echo ""

    # Calculate expected reward range (reward * random(1-5083))
    MIN_REWARD=$(echo "scale=6; $REWARD_READABLE * 1" | bc)
    MAX_REWARD=$(echo "scale=2; $REWARD_READABLE * 5083" | bc)
    echo "Expected reward range: $MIN_REWARD to $MAX_REWARD MATE"
    echo ""

    # Estimate next reward after this claim
    NEXT_REWARD=$(echo "scale=6; $REWARD_READABLE / 2" | bc)
    echo "Reward after next claim: $NEXT_REWARD MATE per call"
    echo ""

    # Estimate claims remaining (each halves the difference)
    CLAIMS_LEFT=0
    TEMP_DIFF=$DIFFERENCE
    while [ $(echo "$TEMP_DIFF > 0" | bc) -eq 1 ]; do
        TEMP_DIFF=$(echo "$TEMP_DIFF / 2" | bc)
        CLAIMS_LEFT=$((CLAIMS_LEFT + 1))

        # Safety limit
        if [ $CLAIMS_LEFT -gt 100 ]; then
            break
        fi
    done
    echo "Approximate claims remaining: $CLAIMS_LEFT"
else
    echo "❌ Status: CANNOT CLAIM"
    echo ""
    echo "The eraTokens has caught up to totalSupply."
    echo "No more rewards can be claimed via recalculateReward()"
fi

echo ""
echo "========================================="

#!/bin/bash

# Simple PAYVVM Contract Verification
# Verifies each contract individually using forge verify-contract
# Run this 15-30 minutes after deployment

set -e

source .env

echo "========================================="
echo "PAYVVM Simple Contract Verification"
echo "========================================="
echo ""

# Deployed addresses from your deployment
STAKING="0x64a47d84de05b9efda4f63fbca2fc8ceb96e6816"
EVVM="0x9486f6c9d28ecdd95aba5bfa6188bbc104d89c3e"
TREASURY="0x3d6cb29a1f97a2cff7a48af96f7ed3a02f6aa38e"
ESTIMATOR="0x5db7cdb7601f9abcfc5089d66b1a3525471bf2ab"
NAMESERVICE="0xa4ba4e9270bde8fbbf4328925959287a72ba0a55"

# Constructor args
ADMIN="0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99"
GOLDEN_FISHER="0x121c631B7aEa24316bD90B22C989Ca008a84E5Ed"
ACTIVATOR="0x60b49b8CB44d3D15559C458886364b725C92634d"

echo "Waiting for Etherscan to index contracts..."
echo "Current time: $(date)"
sleep 5

echo ""
echo "1/5 Verifying Treasury..."
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 300 \
  --compiler-version "0.8.30" \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address)" "$EVVM") \
  --etherscan-api-key $ETHERSCAN_API \
  $TREASURY \
  src/contracts/treasury/Treasury.sol:Treasury && echo "✅ Treasury verified!" || echo "⚠️  Treasury failed or already verified"

echo ""
echo "2/5 Verifying Staking..."
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 300 \
  --compiler-version "0.8.30" \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address)" "$ADMIN" "$GOLDEN_FISHER") \
  --etherscan-api-key $ETHERSCAN_API \
  $STAKING \
  src/contracts/staking/Staking.sol:Staking && echo "✅ Staking verified!" || echo "⚠️  Staking failed or already verified"

echo ""
echo "3/5 Verifying Estimator..."
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 300 \
  --compiler-version "0.8.30" \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address)" "$ACTIVATOR" "$EVVM" "$STAKING" "$ADMIN") \
  --etherscan-api-key $ETHERSCAN_API \
  $ESTIMATOR \
  src/contracts/staking/Estimator.sol:Estimator && echo "✅ Estimator verified!" || echo "⚠️  Estimator failed or already verified"

echo ""
echo "4/5 Verifying NameService..."
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 300 \
  --compiler-version "0.8.30" \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address)" "$EVVM" "$ADMIN") \
  --etherscan-api-key $ETHERSCAN_API \
  $NAMESERVICE \
  src/contracts/nameService/NameService.sol:NameService && echo "✅ NameService verified!" || echo "⚠️  NameService failed or already verified"

echo ""
echo "5/5 Verifying Evvm (complex struct constructor)..."

# Read the input JSON files to reconstruct the exact constructor args
EVVM_NAME=$(cat input/evvmBasicMetadata.json | grep EvvmName | cut -d'"' -f4)
TOKEN_NAME=$(cat input/evvmBasicMetadata.json | grep principalTokenName | cut -d'"' -f4)
TOKEN_SYMBOL=$(cat input/evvmBasicMetadata.json | grep principalTokenSymbol | cut -d'"' -f4)
TOTAL_SUPPLY=$(cat input/evvmAdvancedMetadata.json | grep totalSupply | cut -d':' -f2 | cut -d',' -f1 | tr -d ' ')
ERA_TOKENS=$(cat input/evvmAdvancedMetadata.json | grep eraTokens | cut -d':' -f2 | cut -d',' -f1 | tr -d ' ')
REWARD=$(cat input/evvmAdvancedMetadata.json | grep reward | cut -d':' -f2 | tr -d ' ' | tr -d '}')

# Encode the struct using the exact same format as deployment
EVVM_STRUCT=$(cast abi-encode "f((string,uint256,string,string,address,uint256,uint256,uint256))" "($EVVM_NAME,0,$TOKEN_NAME,$TOKEN_SYMBOL,0x0000000000000000000000000000000000000001,$TOTAL_SUPPLY,$ERA_TOKENS,$REWARD)")

forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 300 \
  --compiler-version "0.8.30" \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address,(string,uint256,string,string,address,uint256,uint256,uint256))" "$ADMIN" "$STAKING" "($EVVM_NAME,0,$TOKEN_NAME,$TOKEN_SYMBOL,0x0000000000000000000000000000000000000001,$TOTAL_SUPPLY,$ERA_TOKENS,$REWARD)") \
  --etherscan-api-key $ETHERSCAN_API \
  $EVVM \
  src/contracts/evvm/Evvm.sol:Evvm && echo "✅ Evvm verified!" || echo "⚠️  Evvm failed or already verified"

echo ""
echo "========================================="
echo "Verification Complete!"
echo "========================================="
echo ""
echo "View your contracts on Etherscan:"
echo "Staking:     https://sepolia.etherscan.io/address/$STAKING#code"
echo "Evvm:        https://sepolia.etherscan.io/address/$EVVM#code"
echo "Estimator:   https://sepolia.etherscan.io/address/$ESTIMATOR#code"
echo "NameService: https://sepolia.etherscan.io/address/$NAMESERVICE#code"
echo "Treasury:    https://sepolia.etherscan.io/address/$TREASURY#code"
echo ""
echo "If verification failed with 'Could not detect the deployment', wait"
echo "10-15 more minutes and run this script again."

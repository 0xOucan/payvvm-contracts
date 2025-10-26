#!/bin/bash

# PAYVVM Contract Verification Script (with --via-ir flag)
# Run this script 10-15 minutes after deployment to verify contracts on Etherscan

set -e

ETHERSCAN_API="3AY1S4FFY97VE93FAJBFJKUPEZDEDKDP4V"
CHAIN_ID=11155111

# Deployed addresses
STAKING="0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816"
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
ESTIMATOR="0x5dB7cDb7601f9ABCfc5089D66b1A3525471bf2aB"
NAMESERVICE="0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"
TREASURY="0x3D6cB29a1F97a2CFf7a48af96F7ED3A02F6aA38E"

# Configuration addresses
ADMIN="0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99"
GOLDEN_FISHER="0x121c631B7aEa24316bD90B22C989Ca008a84E5Ed"
ACTIVATOR="0x60b49b8CB44d3D15559C458886364b725C92634d"

echo "========================================="
echo "PAYVVM Contract Verification (with via-ir)"
echo "========================================="
echo ""
echo "NOTE: All contracts MUST be verified with --via-ir flag"
echo ""

# Wait and check if deployment is indexed
echo "Checking if contracts are indexed on Etherscan..."
sleep 3

# Verify Staking
echo ""
echo "1/5. Verifying Staking contract..."
echo "Address: $STAKING"
forge verify-contract \
  --chain-id $CHAIN_ID \
  --num-of-optimizations 300 \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address)" "$ADMIN" "$GOLDEN_FISHER") \
  --etherscan-api-key $ETHERSCAN_API \
  --watch \
  $STAKING \
  src/contracts/staking/Staking.sol:Staking && echo "✅ Staking verified!" || echo "❌ Staking verification failed or already verified"

# Verify Treasury
echo ""
echo "2/5. Verifying Treasury contract..."
echo "Address: $TREASURY"
forge verify-contract \
  --chain-id $CHAIN_ID \
  --num-of-optimizations 300 \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address)" "$EVVM") \
  --etherscan-api-key $ETHERSCAN_API \
  --watch \
  $TREASURY \
  src/contracts/treasury/Treasury.sol:Treasury && echo "✅ Treasury verified!" || echo "❌ Treasury verification failed or already verified"

# Verify Estimator
echo ""
echo "3/5. Verifying Estimator contract..."
echo "Address: $ESTIMATOR"
forge verify-contract \
  --chain-id $CHAIN_ID \
  --num-of-optimizations 300 \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address)" "$ACTIVATOR" "$EVVM" "$STAKING" "$ADMIN") \
  --etherscan-api-key $ETHERSCAN_API \
  --watch \
  $ESTIMATOR \
  src/contracts/staking/Estimator.sol:Estimator && echo "✅ Estimator verified!" || echo "❌ Estimator verification failed or already verified"

# Verify NameService
echo ""
echo "4/5. Verifying NameService contract..."
echo "Address: $NAMESERVICE"
forge verify-contract \
  --chain-id $CHAIN_ID \
  --num-of-optimizations 300 \
  --via-ir \
  --constructor-args $(cast abi-encode "constructor(address,address)" "$EVVM" "$ADMIN") \
  --etherscan-api-key $ETHERSCAN_API \
  --watch \
  $NAMESERVICE \
  src/contracts/nameService/NameService.sol:NameService && echo "✅ NameService verified!" || echo "❌ NameService verification failed or already verified"

# Verify Evvm (most complex - has struct constructor args)
echo ""
echo "5/5. Verifying Evvm contract..."
echo "Address: $EVVM"
echo "Note: Evvm has complex constructor arguments (struct EvvmMetadata)"

# Use the broadcast run to get the exact constructor args
forge verify-contract \
  --chain-id $CHAIN_ID \
  --num-of-optimizations 300 \
  --via-ir \
  --etherscan-api-key $ETHERSCAN_API \
  --watch \
  $EVVM \
  src/contracts/evvm/Evvm.sol:Evvm && echo "✅ Evvm verified!" || echo "❌ Evvm verification failed - trying with manual constructor args..."

# If automatic verification fails, try with constructor args from deployment
if [ $? -ne 0 ]; then
  echo "Trying alternative verification method for Evvm..."
  EVVM_CONSTRUCTOR_ARGS="00000000000000000000000093d2c57690db077e5d0b3112f1b255c6cb39ac9900000000000000000000000064a47d84de05b9efda4f63fbca2fc8ceb96e681600000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000691ef14d9ee1d2ee434000000000000000000000000000000000000000000000348f78a6cf70e97721a00000000000000000000000000000000000000000000000000004563918244f40000000000000000000000000000000000000000000000000000000000000000000650415956564d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4d61746520746f6b656e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044d41544500000000000000000000000000000000000000000000000000000000"

  forge verify-contract \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 300 \
    --via-ir \
    --constructor-args $EVVM_CONSTRUCTOR_ARGS \
    --etherscan-api-key $ETHERSCAN_API \
    --watch \
    $EVVM \
    src/contracts/evvm/Evvm.sol:Evvm && echo "✅ Evvm verified with manual args!" || echo "❌ Evvm verification failed"
fi

echo ""
echo "========================================="
echo "Verification process completed!"
echo "========================================="
echo ""
echo "Check your contracts on Etherscan:"
echo "Staking:     https://sepolia.etherscan.io/address/$STAKING#code"
echo "Evvm:        https://sepolia.etherscan.io/address/$EVVM#code"
echo "Estimator:   https://sepolia.etherscan.io/address/$ESTIMATOR#code"
echo "NameService: https://sepolia.etherscan.io/address/$NAMESERVICE#code"
echo "Treasury:    https://sepolia.etherscan.io/address/$TREASURY#code"
echo ""
echo "If verification still fails, the contracts may need more time to be indexed."
echo "Wait 10-15 more minutes and run this script again."

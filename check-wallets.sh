#!/bin/bash

echo "All wallets:"
cast wallet list

echo ""
echo "========================================="
echo "Checking monad-deployer address:"
echo "========================================="
cast wallet address --account monad-deployer

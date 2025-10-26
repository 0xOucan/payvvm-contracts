# PAYVVM Name Service Setup Guide

## Overview

Your PAYVVM Name Service is already deployed at:
- **NameService Contract**: `0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55`
- **EVVM Contract**: `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e`
- **Network**: Ethereum Sepolia (Chain ID: 11155111)

We will set up a frontend + indexer in `envioftpayvvm/` to interact with this deployed contract.

## Name Service Features

### Username Format
- Format: `$username.payvvm` (e.g., `$0xoucan.payvvm`)
- Usernames expire after 366 days (renewable)
- Registration uses commit-reveal to prevent front-running

### Key Functions

1. **preRegistrationUsername** - Submit hashed username commitment (30-min window)
2. **registrationUsername** - Reveal and complete registration
3. **renewUsername** - Extend ownership for another 366 days
4. **makeOffer** - Offer to buy a username
5. **acceptOffer** - Sell your username
6. **addCustomMetadata** - Add social links, contact info, etc.

### Pricing
- **Registration Fee**: 100x current EVVM reward = 500 MATE tokens
- **Metadata Operations**: 10x reward = 50 MATE per entry
- **Marketplace Fee**: 0.5% on trades

## Setup Steps

### Step 1: Configure envioftpayvvm

Navigate to the project:
```bash
cd /home/oucan/PayVVM/envioftpayvvm
```

### Step 2: Add Deployed Contracts to Foundry

Copy your deployed contract ABIs:
```bash
# ABIs are in the broadcast folder from PAYVVM deployment
# We'll reference them directly
```

### Step 3: Configure Envio Indexer

The indexer will track:
- Username registrations
- Metadata updates
- Offers and trades
- Renewals

### Step 4: Build Frontend UI

Components to build:
- Username search/lookup
- Registration flow (commit + reveal)
- User profile (show owned usernames)
- Metadata editor
- Marketplace for username trading

### Step 5: Deploy

```bash
# Start local chain (optional for testing)
yarn chain

# Start Envio indexer
pnpm --filter envio-indexer dev

# Start frontend
yarn start
```

## Dual Signature Pattern

Every Name Service operation requires TWO signatures:

1. **Service Signature** - Authorizes the Name Service operation
   - Validates user wants to register/update/trade
   - Uses NameService nonce

2. **EVVM Payment Signature** - Authorizes payment
   - Validates payment of fees
   - Uses EVVM nonce

## Registration Flow

```
User: "I want to register $0xoucan.payvvm"

Step 1: Pre-Registration (Commit)
- Hash: keccak256("0xoucan" + secretNumber)
- Pay: 500 MATE
- Wait: 30 minutes

Step 2: Registration (Reveal)
- Reveal: "0xoucan" + secretNumber
- Verify: Hash matches
- Complete: Ownership granted for 366 days
```

## Integration Points

### With EVVM Core
- Payment processing for fees
- Fisher rewards distribution
- Multi-token support

### With Staking
- Fisher nodes execute transactions
- Earn rewards for processing

### With Treasury
- Fee collection
- Reward distribution

## Next Actions

1. ✅ Contracts are deployed
2. ⏳ Set up contract references in envioftpayvvm
3. ⏳ Configure Envio indexer
4. ⏳ Build frontend UI
5. ⏳ Test registration flow

Ready to start setting this up!

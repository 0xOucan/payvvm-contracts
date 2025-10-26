# EVVM Faucet Services Deployment Summary

## Deployed Contracts (Ethereum Sepolia)

### PYUSD Faucet
- **Address**: `0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a`
- **Etherscan**: https://sepolia.etherscan.io/address/0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a
- **Claim Amount**: 1 PYUSD (1000000 with 6 decimals)
- **Cooldown**: 24 hours
- **Token**: 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9 (PYUSD Sepolia)
- **Status**: ✅ Deployed & Verified

### MATE Faucet
- **Address**: `0x068E9091e430786133439258C4BeeD696939405e`
- **Etherscan**: https://sepolia.etherscan.io/address/0x068E9091e430786133439258C4BeeD696939405e
- **Claim Amount**: 510 MATE (510000000000000000000 with 18 decimals)
- **Cooldown**: 24 hours
- **Token**: 0x0000000000000000000000000000000000000001 (MATE Protocol Token)
- **Status**: ✅ Deployed & Verified

## Common Configuration

- **EVVM**: 0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e
- **EVVM ID**: 1000
- **Owner**: 0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99
- **Network**: Ethereum Sepolia (Chain ID: 11155111)
- **Compiler**: v0.8.30 with via-ir optimization
- **Optimizer Runs**: 300

## Deployment Scripts

### Main Deployment Scripts
```bash
# Deploy PYUSD Faucet (interactive wallet prompt)
./deploy-pyusd-faucet.sh

# Deploy MATE Faucet (interactive wallet prompt)
./deploy-mate-faucet.sh
```

### Verification Scripts
```bash
# Verify PYUSD Faucet on Etherscan
./verify-pyusd-faucet.sh

# Verify MATE Faucet on Etherscan
./verify-mate-faucet.sh
```

## How the Faucets Work

### User Flow
1. **User**: Connects wallet to frontend
2. **User**: Signs claim message (EIP-191) - no gas required
3. **Frontend**: Submits signed claim to fishing pool API
4. **Fisher Bot**: Polls fishing pool every 2 seconds
5. **Fisher Bot**: Executes claim transaction and pays gas
6. **EVVM**: Transfers tokens from faucet balance to user's EVVM balance

### Signature Format
- **PYUSD**: `{evvmID},claimPyusd,{claimer},{nonce}`
- **MATE**: `{evvmID},claimMate,{claimer},{nonce}`

Example:
```
1000,claimMate,0x9c77c6fafc1eb0821f1de12972ef0199c97c6e45,1730000000000
```

### Nonce System
- **Type**: Timestamp-based (Date.now())
- **Validation**: Async (not sequential)
- **Replay Protection**: Contract tracks used nonces per user

## Next Steps

### 1. Fund the Faucets

Both faucets need to be funded with tokens via EVVM. You have two options:

#### Option A: Direct EVVM Payment (Recommended for MATE)
```bash
# Use EVVM pay() function to send MATE to faucet address
# This is the recommended approach for MATE tokens
```

#### Option B: Treasury Deposit (For PYUSD)
```bash
# 1. Transfer PYUSD to treasury contract
# 2. Call treasury.deposit() with faucet address as recipient
```

### 2. Test the Faucets

1. Visit the frontend (running on localhost:3000)
2. Connect your wallet
3. Navigate to the faucet services page
4. Try claiming from both faucets
5. Monitor the fisher bot logs for execution
6. Verify balances update in EVVM

### 3. Monitor Operations

#### Check Faucet Balances
```bash
# Using cast
cast call 0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a "getFaucetBalance()(uint256)" --rpc-url https://sepolia.gateway.tenderly.co

cast call 0x068E9091e430786133439258C4BeeD696939405e "getFaucetBalance()(uint256)" --rpc-url https://sepolia.gateway.tenderly.co
```

#### Check User Eligibility
```bash
cast call 0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a "canClaim(address)(bool,uint256)" YOUR_ADDRESS --rpc-url https://sepolia.gateway.tenderly.co
```

#### Fisher Bot Status
Check fisher bot logs in the terminal where it's running:
```bash
yarn fisher:start
```

## Frontend Integration Status

✅ **Hooks Updated**:
- `packages/nextjs/hooks/payvvm/usePyusdFaucet.ts`
- `packages/nextjs/hooks/payvvm/useMateFaucetService.ts`

✅ **Components Updated**:
- `packages/nextjs/components/payvvm/MateFaucetService.tsx`

✅ **Fisher Bot Updated**:
- `packages/nextjs/fishing/fisher-bot.ts`
- Monitors both PYUSD and MATE claim pools
- Executes claims automatically

✅ **API Endpoints Created**:
- `/api/fishing/submit-claim` (PYUSD claims)
- `/api/fishing/submit-mate-claim` (MATE claims)

## Troubleshooting

### Faucet is Empty
- Check faucet balance with `getFaucetBalance()`
- Fund the faucet via EVVM payment

### Claim Fails with "Cooldown Active"
- Users must wait 24 hours between claims
- Check `lastClaimTime(address)` on contract

### Fisher Bot Not Executing
- Verify fisher bot is running: `yarn fisher:start`
- Check fishing pool API endpoints are accessible
- Verify fisher wallet has ETH for gas

### Signature Invalid
- Ensure correct EVVM ID is used (1000)
- Verify message format: `{evvmID},{functionName},{claimer},{nonce}`
- Check signature is EIP-191 format

## Contract Owner Functions

### Update Claim Amount
```solidity
function updateClaimAmount(uint256 newAmount) external onlyOwner
```

### Update Cooldown Period
```solidity
function updateCooldownPeriod(uint256 newPeriod) external onlyOwner
```

### Emergency Withdraw
```solidity
function emergencyWithdraw(address token, uint256 amount) external onlyOwner
```

### Transfer Ownership
```solidity
function transferOwnership(address newOwner) external onlyOwner
```

## Security Considerations

- ✅ EIP-191 signature verification
- ✅ Nonce replay protection
- ✅ Cooldown period enforcement
- ✅ Owner-only administrative functions
- ✅ Balance checks before claims
- ⚠️ Fisher bot private key must be kept secure
- ⚠️ Owner wallet must be kept secure

## Gas Costs

**Deployment**:
- PYUSD Faucet: 0.000001034442 ETH (1,034,442 gas)
- MATE Faucet: 0.000001034058 ETH (1,034,058 gas)

**Per Claim** (estimated):
- ~150,000 - 200,000 gas
- Paid by fisher bot, not users

## Repository Structure

```
PAYVVM/
├── src/contracts/services/
│   ├── PyusdFaucet.sol
│   └── MateFaucet.sol
├── script/
│   ├── DeployPyusdFaucet.s.sol
│   └── DeployMateFaucet.s.sol
├── deploy-pyusd-faucet.sh
├── deploy-mate-faucet.sh
├── verify-pyusd-faucet.sh
└── verify-mate-faucet.sh

envioftpayvvm/packages/nextjs/
├── hooks/payvvm/
│   ├── usePyusdFaucet.ts
│   └── useMateFaucetService.ts
├── components/payvvm/
│   └── MateFaucetService.tsx
├── fishing/
│   └── fisher-bot.ts
└── app/api/fishing/
    ├── submit-claim/
    └── submit-mate-claim/
```

## Git Commit History

1. ✅ Created PyusdFaucet.sol and MateFaucet.sol contracts
2. ✅ Created deployment scripts with interactive wallet
3. ✅ Created frontend hooks and components
4. ✅ Integrated with fishing pool system
5. ✅ Deployed both contracts to Sepolia
6. ✅ Verified both contracts on Etherscan
7. ✅ Updated frontend with deployed addresses
8. ✅ Fixed TypeScript validation errors

## Support & Documentation

- **EVVM Service Docs**: https://www.evvm.info/docs/HowToMakeAEVVMService
- **EIP-191 Standard**: https://eips.ethereum.org/EIPS/eip-191
- **Foundry Docs**: https://book.getfoundry.sh/
- **Etherscan API**: https://docs.etherscan.io/

---

**Deployment Date**: October 25, 2025
**Network**: Ethereum Sepolia (Testnet)
**Branch**: `pyusdfaucet`

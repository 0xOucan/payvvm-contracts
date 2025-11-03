# PAYVVM Contracts

> **Smart contracts, deployment scripts, and faucet services for the EVVM ecosystem**

This repository contains the core EVVM contracts, EVVM service contracts (faucets), deployment infrastructure, and testing utilities for the PAYVVM platform.

[![Ethereum Sepolia](https://img.shields.io/badge/Network-Ethereum%20Sepolia-blue)](https://sepolia.etherscan.io)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-orange)](https://soliditylang.org)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-red)](https://getfoundry.sh)

---

## 📦 Contents

### Core EVVM Contracts
Located in `src/contracts/`:

| Contract | Purpose | Address (Sepolia) |
|----------|---------|-------------------|
| **Evvm.sol** | Core virtual machine with payment execution | `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e` |
| **NameService.sol** | Decentralized username registry | `0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55` |
| **Staking.sol** | Token staking mechanism | `0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816` |
| **Estimator.sol** | Reward calculation engine | `0x5dB7cDb7601f9ABCfc5089D66b1A3525471bf2aB` |
| **Treasury.sol** | Asset management & custody | `0x3D6cB29a1F97a2CFf7a48af96F7ED3A02F6aA38E` |

### EVVM Services (Faucets)
Located in `src/contracts/services/`:

| Service | Purpose | Address (Sepolia) |
|---------|---------|-------------------|
| **PyusdFaucet.sol** | Gasless PYUSD distribution | `0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a` |
| **MateFaucet.sol** | Gasless MATE distribution | `0x068E9091e430786133439258C4BeeD696939405e` |

Both faucets are **verified on Etherscan** and use **EIP-191 signature-based gasless claims**.

---

## 🚀 Quick Start

### Prerequisites

- **Foundry** - Smart contract development framework
- **Cast** - Command-line tool for Ethereum interaction
- **Node.js** v18+ (for some helper scripts)
- **Git** for version control

### Installation

```bash
# Clone the repository
git clone git@github.com:0xOucan/payvvm-contracts.git
cd payvvm-contracts

# Install dependencies and compile contracts
make install

# Or manually:
forge install
forge build --via-ir
```

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Configure your .env file
ETHERSCAN_API=your_etherscan_api_key
RPC_URL_SEPOLIA=your_sepolia_rpc_url
```

### Wallet Configuration

The deployment scripts use Foundry's keystore for secure private key management:

```bash
# Import your deployer wallet (interactive password prompt)
cast wallet import monad-deployer --interactive

# List available wallets
cast wallet list
```

---

## 🛠 Development

### Compile Contracts

All contracts **must** be compiled with `--via-ir` flag due to contract size optimization:

```bash
# Using Makefile (recommended)
make compile

# Or using forge directly
forge build --via-ir
```

### Run Tests

```bash
# Run all tests
forge test --via-ir

# Run specific test
forge test --match-contract TestContractName --via-ir

# Run with verbose output
forge test --via-ir -vvv
```

### Check Contract Sizes

```bash
make seeSizes
```

---

## 📝 Deployment

### EVVM Initialization Wizard

Before deploying core EVVM contracts, configure deployment parameters:

```bash
./evvm-init.sh
```

This creates configuration files in `input/`:
- `address.json` - Admin, fisher, activator addresses
- `evvmBasicMetadata.json` - EVVM name, ID, token details
- `evvmAdvancedMetadata.json` - Supply and reward parameters

### Deploy Core EVVM Contracts

```bash
# Deploy to Ethereum Sepolia
make deployTestnet NETWORK=eth

# Deploy to Arbitrum Sepolia (default)
make deployTestnet NETWORK=arb

# Local development (Anvil)
make anvil  # Run in separate terminal
make deployTestnetAnvil
```

### Deploy Faucet Services

#### PYUSD Faucet

```bash
./deploy-pyusd-faucet.sh
```

**Features:**
- Claim amount: 1 PYUSD (1e6 with 6 decimals)
- Cooldown: 24 hours
- Automatic Etherscan verification
- Interactive wallet password prompt

#### MATE Faucet

```bash
./deploy-mate-faucet.sh
```

**Features:**
- Claim amount: 510 MATE (510e18 with 18 decimals)
- Cooldown: 24 hours
- Automatic Etherscan verification
- Interactive wallet password prompt

### Verify Contracts

If verification fails during deployment, use standalone scripts:

```bash
# Verify PYUSD Faucet
./verify-pyusd-faucet.sh

# Verify MATE Faucet
./verify-mate-faucet.sh
```

---

## 🎯 Faucet Services

### How Faucets Work

The faucet services use **gasless claiming** via EIP-191 signatures:

1. User signs claim message with wallet (no gas required)
2. Signature submits to fishing pool API
3. Fisher bot polls API and executes claim
4. Tokens sent to user's EVVM balance
5. 24-hour cooldown enforced per address

### Signature Format

**PYUSD Claim:**
```
{evvmID},claimPyusd,{claimer},{nonce}
```

**MATE Claim:**
```
{evvmID},claimMate,{claimer},{nonce}
```

### Faucet Functions

#### claimPyusd / claimMate
```solidity
function claimPyusd(
    address claimer,
    uint256 nonce,
    bytes memory signature
) external
```

#### canClaim
```solidity
function canClaim(address user) external view returns (
    bool eligible,
    uint256 remainingTime
)
```

#### getFaucetBalance
```solidity
function getFaucetBalance() external view returns (uint256)
```

### Admin Functions

#### Update Claim Amount
```solidity
function updateClaimAmount(uint256 newAmount) external onlyOwner
```

#### Update Cooldown Period
```solidity
function updateCooldownPeriod(uint256 newPeriod) external onlyOwner
```

#### Emergency Withdraw
```solidity
function emergencyWithdraw(address token, uint256 amount) external onlyOwner
```

---

## 💼 Payroll & Batch Payments (dispersePay)

### Overview

EVVM supports batch PYUSD payments through the `dispersePay()` function, enabling single-signature multi-recipient transfers for payroll, airdrops, and distribution workflows.

### Status: ⚠️ Under Investigation

The payvvm-frontend implementation of batch payments via `dispersePay()` is experiencing `InvalidSignature()` errors despite mathematically valid signatures. Extensive debugging has verified:

- ✅ Signatures are mathematically valid (off-chain recovery passes)
- ✅ Message construction matches EVVM specification exactly
- ✅ Hash calculation (SHA256 of ABI-encoded recipients) is correct
- ✅ Async nonce availability confirmed
- ✅ User balance sufficient
- ✅ Recipient amounts sum correctly
- ✅ All addresses properly lowercased
- ✅ priorityFlag=true (async nonces) to prevent race conditions

**Yet on-chain execution reverts with `InvalidSignature()`.**

### Signature Format

```
{evvmID},dispersePay,{recipientsHash},{token},{totalAmount},{priorityFee},{nonce},{priorityFlag},{executor}

Where:
- recipientsHash = sha256(abi.encode(DispersePayMetadata[]))
- DispersePayMetadata = (uint256 amount, address to_address, string to_identity)
- All addresses must be lowercase
- priorityFlag: true (async) or false (sync)
```

**Example:**
```
1000,dispersePay,0x0e94b2e8096216bee7af2f861f9cd9470928c9629fce680fe1cebe6c7eb98950,0xcac524bca292aaade2df8a05cc58f0a65b1b3bb9,30000,0,26,true,0x0000000000000000000000000000000000000000
```

### Contract Function

```solidity
function dispersePay(
    address from,
    DispersePayMetadata[] memory toData,
    address token,
    uint256 amount,
    uint256 priorityFee,
    uint256 nonce,
    bool priorityFlag,
    address executor,
    bytes memory signature
) external
```

### Diagnostic Tools

The payvvm-frontend includes command-line diagnostic tools for debugging dispersePay transactions:

```bash
# Analyze any dispersePay transaction
npx tsx analyze-any-tx.ts <tx-hash>

# Verify recipient amounts match declared total
npx tsx analyze-recipients.ts <tx-hash>

# Check async nonce availability
npx tsx check-async-nonce.ts

# Check user EVVM balance
npx tsx check-evvm-balance.ts

# Simulate contract signature verification
npx tsx simulate-contract-verification.ts <tx-hash>
```

### Changes Made (payvvm-frontend)

- Switched from synchronous to asynchronous nonces (`priorityFlag: false` → `true`)
- Ensured consistent address lowercasing in signature construction
- Added comprehensive debug logging in fisher executor
- Created suite of diagnostic tools for verification

### Next Steps

- EVVM team investigation of contract signature verification logic
- Comparison with working `pay()` (single-recipient) signature flow
- Possible contract-side debugging or testnet re-deployment

See `payvvm-frontend` repository for implementation details and diagnostic tools.

---

## 🔧 Utility Scripts

### Check Faucet Status

```bash
# Check PYUSD faucet balance
cast call 0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a \
  "getFaucetBalance()(uint256)" \
  --rpc-url https://sepolia.gateway.tenderly.co

# Check MATE faucet balance
cast call 0x068E9091e430786133439258C4BeeD696939405e \
  "getFaucetBalance()(uint256)" \
  --rpc-url https://sepolia.gateway.tenderly.co

# Check user eligibility
cast call 0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a \
  "canClaim(address)(bool,uint256)" \
  YOUR_ADDRESS \
  --rpc-url https://sepolia.gateway.tenderly.co
```

### Fund Faucets

Faucets need to be funded via EVVM payments:

```bash
# For PYUSD: Transfer PYUSD to treasury, then deposit to faucet
# For MATE: Send MATE directly via EVVM pay() to faucet address
```

---

## 📂 Repository Structure

```
payvvm-contracts/
├── src/
│   ├── contracts/
│   │   ├── Evvm.sol                    # Core VM
│   │   ├── NameService.sol             # Username registry
│   │   ├── Staking.sol                 # Token staking
│   │   ├── Estimator.sol               # Reward calculations
│   │   ├── Treasury.sol                # Asset management
│   │   └── services/
│   │       ├── PyusdFaucet.sol         # PYUSD faucet service
│   │       └── MateFaucet.sol          # MATE faucet service
│   └── lib/
│       ├── SignatureRecover.sol        # EIP-191/712 verification
│       └── AdvancedStrings.sol         # String utilities
│
├── script/
│   ├── DeployTestnet.s.sol             # Core EVVM deployment
│   ├── DeployPyusdFaucet.s.sol         # PYUSD faucet deployment
│   └── DeployMateFaucet.s.sol          # MATE faucet deployment
│
├── deploy-pyusd-faucet.sh              # PYUSD deployment + verification
├── deploy-mate-faucet.sh               # MATE deployment + verification
├── verify-pyusd-faucet.sh              # Standalone PYUSD verification
├── verify-mate-faucet.sh               # Standalone MATE verification
├── evvm-init.sh                        # Interactive config wizard
│
├── input/                              # Deployment configuration
│   ├── address.json
│   ├── evvmBasicMetadata.json
│   └── evvmAdvancedMetadata.json
│
├── broadcast/                          # Deployment artifacts
├── foundry.toml                        # Foundry configuration
├── makefile                            # Build automation
├── FAUCET_DEPLOYMENT_SUMMARY.md        # Faucet deployment docs
└── README.md                           # This file
```

---

## 🔐 Security

### Best Practices

- ✅ Never commit private keys
- ✅ Use Foundry keystore for secure key management
- ✅ `.env` files are gitignored
- ✅ Signature replay protection via nonces
- ✅ Admin-only functions protected with `onlyOwner`
- ✅ Balance checks before transfers

### Testnet Only

⚠️ **Warning**: These contracts are currently deployed on **Ethereum Sepolia testnet** only. Mainnet deployment requires additional security audits and testing.

---

## 📖 Documentation

### Project Documentation
- **FAUCET_DEPLOYMENT_SUMMARY.md** - Complete faucet deployment guide
- **Makefile** - Available build and deployment commands
- **foundry.toml** - Compiler settings and optimizations

### External Documentation
- **EVVM Documentation**: [evvm.info/docs](https://www.evvm.info/docs)
- **EIP-191 Signature Standard**: [eips.ethereum.org/EIPS/eip-191](https://eips.ethereum.org/EIPS/eip-191)
- **Foundry Book**: [book.getfoundry.sh](https://book.getfoundry.sh)

### Frontend Integration

The PAYVVM frontend repository integrates with these contracts:
- **Repository**: [0xOucan/PAYVVM](https://github.com/0xOucan/PAYVVM)
- **Faucets Page**: `/faucets` - User-friendly claim interface
- **PAYVVM Page**: `/payvvm` - Complete EVVM dashboard

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Compile with via-ir: `forge build --via-ir`
4. Test your changes: `forge test --via-ir`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

Built with ❤️ by **0xOucan**

- GitHub: [@0xOucan](https://github.com/0xOucan)
- EVVM Registry: [EVVM #1000](https://www.evvm.info/evvms/1000)

**Co-Developed with**:
- Claude (Anthropic) - AI pair programming assistant

---

## 🙏 Acknowledgments

- **EVVM Team** - For the innovative virtual machine architecture
- **OpenZeppelin** - Standard contract library
- **Foundry** - Best-in-class Ethereum development framework

---

## 🔗 Links

| Resource | URL |
|----------|-----|
| **Contracts Repo** | https://github.com/0xOucan/payvvm-contracts |
| **Frontend Repo** | https://github.com/0xOucan/PAYVVM |
| **EVVM Registry** | https://www.evvm.info/evvms/1000 |
| **EVVM Contract** | https://sepolia.etherscan.io/address/0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e |
| **PYUSD Faucet** | https://sepolia.etherscan.io/address/0x74F7A28aF1241cfBeC7c6DBf5e585Afc18832a9a |
| **MATE Faucet** | https://sepolia.etherscan.io/address/0x068E9091e430786133439258C4BeeD696939405e |

---

<div align="center">

**Smart contracts powering gasless, user-friendly Web3 payments**

[![Ethereum](https://img.shields.io/badge/Ethereum-Sepolia-blue)](https://sepolia.etherscan.io)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.30-orange)](https://soliditylang.org)
[![Foundry](https://img.shields.io/badge/Foundry-Latest-red)](https://getfoundry.sh)

</div>

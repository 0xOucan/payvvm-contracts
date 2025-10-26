# PAYVVM Name Service Complete Guide

## 🎯 What is PAYVVM Name Service?

PAYVVM Name Service lets you register human-readable usernames like **$0xoucan.payvvm** instead of using long wallet addresses. Think of it like ENS (Ethereum Name Service) but specifically for your PAYVVM ecosystem.

## 📋 Current Status

✅ **Deployed & Verified Contracts**
- NameService: `0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55`
- EVVM: `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e`
- Network: Ethereum Sepolia

✅ **Registered in EVVM Registry**
- EVVM ID: 1000 (First Public EVVM!)

⏳ **Next: Frontend & Indexer Setup**

## 🏗️ Architecture

```
PAYVVM Name Service Ecosystem
├── Smart Contracts (Deployed on Sepolia)
│   ├── NameService.sol - Username registration & management
│   ├── Evvm.sol - Payment processing & rewards
│   ├── Staking.sol - Fisher rewards
│   └── Treasury.sol - Fee collection
│
├── Indexer (Envio HyperIndex)
│   ├── Indexes username registrations
│   ├── Tracks metadata updates
│   └── Monitors marketplace activity
│
└── Frontend (Next.js + Scaffold-ETH 2)
    ├── Username search & registration
    ├── Profile management
    ├── Metadata editor
    └── Username marketplace
```

## 💡 Key Features

### 1. Username Registration
- **Format**: `$username.payvvm`
- **Duration**: 366 days (renewable)
- **Protection**: Commit-reveal prevents front-running
- **Cost**: 500 MATE tokens (100x reward)

### 2. Custom Metadata
- Add social media links
- Contact information
- Custom fields (key-value pairs)
- **Cost**: 50 MATE per entry (10x reward)

### 3. Username Marketplace
- Make offers to buy usernames
- Accept/reject offers
- **Fee**: 0.5% marketplace fee

### 4. Gasless Transactions
- Users can pay zero gas fees
- Fisher nodes earn rewards for processing
- PAYVVM covers transaction costs

## 🔐 How Registration Works

### The Commit-Reveal Process

**Why?** Prevents front-running (someone seeing your desired username and registering it first)

**Step 1: Commit (Pre-Registration)**
```
1. Choose username: "0xoucan"
2. Choose secret number: 12345
3. Create hash: keccak256("0xoucan12345")
4. Submit hash + pay 500 MATE
5. Wait 30 minutes
```

**Step 2: Reveal (Registration)**
```
1. After 30 minutes, reveal:
   - Username: "0xoucan"
   - Secret: 12345
2. Contract verifies hash matches
3. You own $0xoucan.payvvm for 366 days!
```

### Dual Signature System

Every operation requires **TWO signatures**:

1. **Name Service Signature**
   - Authorizes the specific action (register, renew, etc.)
   - Uses NameService nonce

2. **EVVM Payment Signature**
   - Authorizes payment of fees
   - Uses EVVM nonce

This prevents unauthorized payments and replay attacks.

## 📦 Setup Instructions

### Prerequisites

```bash
# Check you're in the right directory
cd /home/oucan/PayVVM
```

### Quick Setup

Run the automated setup script:

```bash
./setup-payvvm-nameservice.sh
```

This will:
1. Install dependencies
2. Configure Sepolia network
3. Set up deployed contract addresses
4. Create Envio indexer config
5. Generate environment files

### Manual Setup (if needed)

<details>
<summary>Click to expand manual setup steps</summary>

1. **Navigate to envioftpayvvm**
   ```bash
   cd /home/oucan/PayVVM/envioftpayvvm
   ```

2. **Install dependencies**
   ```bash
   yarn install
   ```

3. **Configure network** (edit `packages/nextjs/scaffold.config.ts`)
   ```typescript
   targetNetworks: [chains.sepolia]
   ```

4. **Add contract addresses** (edit `packages/nextjs/contracts/deployedContracts.ts`)
   ```typescript
   11155111: {  // Sepolia
     NameService: {
       address: "0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55",
       abi: [...]
     }
   }
   ```

5. **Configure Envio** (`packages/envio/config.yaml`)
   ```yaml
   networks:
     - id: 11155111
       contracts:
         - name: NameService
           address: ["0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55"]
   ```

</details>

## 🚀 Running the Application

### Terminal 1: Frontend

```bash
cd /home/oucan/PayVVM/envioftpayvvm
yarn start
```

Opens at: http://localhost:3000

### Terminal 2: Indexer (Optional)

```bash
cd /home/oucan/PayVVM/envioftpayvvm/packages/envio
pnpm codegen
pnpm dev
```

## 🎨 Frontend Components to Build

### 1. Username Search
```typescript
// packages/nextjs/app/nameservice/search/page.tsx
- Input field for username
- Shows owner, expiration, metadata
- "Make Offer" button if owned by someone else
```

### 2. Registration Flow
```typescript
// packages/nextjs/app/nameservice/register/page.tsx
- Step 1: Enter desired username
- Step 2: Pay & commit (pre-registration)
- Step 3: Wait 30 minutes (countdown timer)
- Step 4: Complete registration (reveal)
```

### 3. User Dashboard
```typescript
// packages/nextjs/app/nameservice/dashboard/page.tsx
- List of owned usernames
- Expiration dates
- Renew buttons
- Metadata editor
- View/Manage offers
```

### 4. Marketplace
```typescript
// packages/nextjs/app/nameservice/marketplace/page.tsx
- Browse available usernames
- Active offers
- Recent sales
```

## 💻 Example: Registering $0xoucan.payvvm

### Using the Frontend (Once Built)

1. Connect wallet with MATE tokens
2. Go to /nameservice/register
3. Enter: "0xoucan"
4. Click "Pre-Register" (pays 500 MATE)
5. Wait 30 minutes
6. Click "Complete Registration"
7. Done! You own $0xoucan.payvvm

### Using Direct Contract Calls

<details>
<summary>Click for advanced usage</summary>

```bash
# Step 1: Pre-Registration
SECRET=12345
USERNAME="0xoucan"
HASH=$(cast keccak "0xoucan12345")

cast send 0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55 \
  "preRegistrationUsername(address,bytes32,uint256,bytes,uint256)" \
  $YOUR_ADDRESS \
  $HASH \
  $NONCE \
  $SIGNATURE \
  0 \
  --account monad-deployer

# Step 2: Wait 30 minutes

# Step 3: Registration
cast send 0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55 \
  "registrationUsername(...)" \
  $YOUR_ADDRESS \
  "0xoucan" \
  12345 \
  ... \
  --account monad-deployer
```

</details>

## 📊 Economics

### Pricing

| Operation | Cost | Notes |
|-----------|------|-------|
| Registration | 500 MATE | 100x current reward |
| Renewal | 500 MATE | Same as registration |
| Add Metadata | 50 MATE | 10x reward per entry |
| Marketplace Fee | 0.5% | On successful trades |

### Where Fees Go

- **70%** - Treasury (protocol revenue)
- **30%** - Fisher rewards (for processing)

## 🔧 Developer Resources

### Contract Addresses (Sepolia)

```typescript
const PAYVVM_CONTRACTS = {
  EVVM: "0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e",
  NameService: "0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55",
  Staking: "0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816",
  Estimator: "0x5dB7cDb7601f9ABCfc5089D66b1A3525471bf2aB",
  Treasury: "0x3D6cB29a1F97a2CFf7a48af96F7ED3A02F6aA38E"
};
```

### Key Functions

```solidity
// Check if username is available
function verifyStrictAndGetOwnerOfIdentity(string username)
  returns (address owner)

// Get username metadata
function getUsernameMetadata(string username)
  returns (address owner, uint256 expiration, uint256 registration)

// Pre-register username
function preRegistrationUsername(
  address user,
  bytes32 hash,
  uint256 nonce,
  bytes signature,
  uint256 priorityFee
)

// Complete registration
function registrationUsername(
  address user,
  string username,
  uint256 secret,
  uint256 nonce,
  bytes signature,
  uint256 priorityFee_EVVM,
  uint256 nonce_EVVM,
  bool priorityFlag_EVVM,
  bytes signature_EVVM
)
```

### Events to Index

```solidity
event UsernameRegistered(
  address indexed owner,
  string username,
  uint256 expirationDate
)

event UsernameRenewed(
  address indexed owner,
  string username,
  uint256 newExpirationDate
)

event MetadataAdded(
  address indexed owner,
  string username,
  string key,
  string value
)

event OfferMade(
  address indexed from,
  address indexed to,
  string username,
  uint256 amount
)

event OfferAccepted(
  address indexed from,
  address indexed to,
  string username,
  uint256 amount
)
```

## 🐛 Troubleshooting

### Common Issues

**"Nonce already used"**
- Each nonce can only be used once
- Increment your nonce for each transaction

**"Invalid signature"**
- Ensure you're signing the correct message format
- Check that you're using EIP-191 format

**"Pre-registration not found"**
- Wait 30 minutes after pre-registration
- Ensure hash matches (username + secret)

**"Username already taken"**
- Try a different username
- Or make an offer to current owner

## 🎯 Roadmap

### Phase 1: Current (Setup)
- ✅ Contracts deployed & verified
- ⏳ Frontend setup
- ⏳ Indexer configuration

### Phase 2: Core Features
- Username registration UI
- Search & lookup
- Profile management
- Metadata editor

### Phase 3: Marketplace
- Browse usernames
- Make/accept offers
- Trading interface

### Phase 4: Advanced
- Subdomain support ($alice.$0xoucan.payvvm)
- Reverse resolution (address → username)
- Integration with other PAYVVM services
- Mobile app (Telegram Mini App)

## 📚 Additional Resources

- **EVVM Docs**: https://www.evvm.info/docs
- **Name Service Docs**: https://www.evvm.info/docs/NameService/Introduction
- **Your EVVM**: https://www.evvm.info/evvms/1000
- **Contracts on Etherscan**: https://sepolia.etherscan.io/address/0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55

## 🤝 Support

Need help? Check:
1. This guide
2. EVVM documentation
3. Etherscan contract page
4. GitHub issues

---

**Ready to register $0xoucan.payvvm?** Run the setup script and let's build the frontend! 🚀

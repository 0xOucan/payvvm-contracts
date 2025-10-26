# PAYVVM Name Service - Quick Start

## 🎯 Goal

Build a web app where users can register usernames like **$0xoucan.payvvm** instead of using wallet addresses.

## ✅ What's Already Done

1. ✅ **Contracts Deployed** - NameService live on Sepolia
2. ✅ **Contracts Verified** - All on Etherscan
3. ✅ **EVVM Registered** - ID 1000 in registry
4. ✅ **Setup Script Ready** - Automated configuration

## 🚀 Quick Start (3 Steps)

### Step 1: Run Setup Script

```bash
cd /home/oucan/PayVVM
./setup-payvvm-nameservice.sh
```

This configures envioftpayvvm to work with your deployed contracts.

### Step 2: Start Frontend

```bash
cd /home/oucan/PayVVM/envioftpayvvm
yarn start
```

Opens at: http://localhost:3000

### Step 3: Build Name Service UI

The setup script creates the foundation. Now you need to build:

1. **Username Registration Page** - Let users register names
2. **Search Page** - Look up existing usernames
3. **Dashboard** - Manage owned usernames
4. **Marketplace** - Trade usernames

## 📁 Project Structure

```
/home/oucan/PayVVM/
├── PAYVVM/                          # Original deployment (completed)
│   ├── Deployed contracts
│   ├── Verified on Etherscan
│   └── Registered in EVVM registry
│
├── envioftpayvvm/                   # Name Service Frontend (next step)
│   ├── packages/
│   │   ├── foundry/                # Contract references
│   │   ├── nextjs/                 # Frontend UI
│   │   └── envio/                  # Blockchain indexer
│   └── After setup:
│       ├── Configured for Sepolia
│       ├── Contract addresses set
│       └── Ready to build UI
│
└── Setup Documentation
    ├── PAYVVM_NAME_SERVICE_GUIDE.md      # Complete guide
    ├── PAYVVM_NAME_SERVICE_SETUP.md       # Technical details
    └── README_NAMESERVICE.md              # This file
```

## 🎨 What to Build Next

### Priority 1: Username Lookup

```typescript
// packages/nextjs/app/nameservice/page.tsx
// Simple search: Enter username → Show owner & metadata
```

### Priority 2: Registration Flow

```typescript
// Two-step process:
// 1. Pre-register (commit hash)
// 2. Register (reveal username)
```

### Priority 3: User Dashboard

```typescript
// Show user's owned usernames
// Renewal functionality
// Metadata management
```

## 💡 Key Concepts

### Username Format
- Starts with `$`
- Example: `$0xoucan.payvvm`
- Lowercase only
- No spaces or special chars

### Registration Cost
- **500 MATE tokens** per username
- **366 days** of ownership
- Renewable for same price

### How It Works
1. User commits hash of (username + secret)
2. Pays 500 MATE
3. Waits 30 minutes
4. Reveals username + secret
5. Gets ownership if hash matches

### Why Commit-Reveal?
Prevents front-running: Without this, someone could see your transaction and register the username before you!

## 📚 Documentation

- **Complete Guide**: `PAYVVM_NAME_SERVICE_GUIDE.md`
- **Setup Details**: `PAYVVM_NAME_SERVICE_SETUP.md`
- **Deployment Info**: `PAYVVM/DEPLOYMENT_SUMMARY.md`
- **EVVM Docs**: https://www.evvm.info/docs

## 🔗 Important Links

### Your Contracts (Sepolia)
- **NameService**: https://sepolia.etherscan.io/address/0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55
- **EVVM**: https://sepolia.etherscan.io/address/0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e
- **Registry**: https://www.evvm.info/evvms/1000

### Development
- **Frontend**: http://localhost:3000 (after `yarn start`)
- **Scaffold-ETH Docs**: https://docs.scaffoldeth.io/
- **Envio Docs**: https://docs.envio.dev/

## 🛠️ Development Workflow

```bash
# Terminal 1: Frontend
cd /home/oucan/PayVVM/envioftpayvvm
yarn start

# Terminal 2: Indexer (optional)
cd /home/oucan/PayVVM/envioftpayvvm/packages/envio
pnpm codegen
pnpm dev

# Terminal 3: Watch for changes
yarn next:lint
```

## 🎯 Next Actions

1. **Run the setup script** (if you haven't)
   ```bash
   ./setup-payvvm-nameservice.sh
   ```

2. **Start the frontend**
   ```bash
   cd envioftpayvvm && yarn start
   ```

3. **Begin building UI components**
   - Start with username search
   - Add registration flow
   - Build dashboard

4. **Test with real transactions**
   - Get MATE tokens (from your treasury)
   - Register your first username: `$0xoucan.payvvm`
   - Add metadata (Twitter, GitHub, etc.)

## 🎁 Bonus Features to Add Later

- **Subdomain support**: `$alice.$0xoucan.payvvm`
- **Username marketplace**: Buy/sell usernames
- **Reverse lookup**: Address → Username
- **Avatar support**: NFT profile pictures
- **Telegram integration**: Register via bot
- **QR codes**: Share your username

## 🚨 Important Notes

1. **This is testnet** - Use Sepolia ETH and test MATE tokens
2. **Wallet required** - Connect MetaMask or similar
3. **Gas fees** - You pay Sepolia ETH for transactions
4. **MATE tokens** - You need 500 MATE to register

## ❓ Need Help?

1. Check `PAYVVM_NAME_SERVICE_GUIDE.md` - Detailed explanations
2. Read EVVM docs - https://www.evvm.info/docs
3. Look at contract code - In `PAYVVM/src/contracts/nameService/`
4. Check Etherscan - See real transactions and events

---

**Ready?** Run `./setup-payvvm-nameservice.sh` and start building! 🚀

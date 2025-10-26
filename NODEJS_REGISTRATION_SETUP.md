# Node.js Registration Setup

This uses **ethers.js** (same as web interface) for guaranteed signature compatibility.

## Setup (One-time)

```bash
# 1. Install Node.js if needed
node --version  # Should be v16 or higher

# If not installed:
# curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
# sudo apt-get install -y nodejs

# 2. Install dependencies
npm install ethers dotenv

# 3. Make script executable
chmod +x register-name-nodejs.js
```

## Usage

```bash
# Register a username
node register-name-nodejs.js test

# Or
./register-name-nodejs.js test
```

## What It Does

1. ✅ Uses **ethers.js signMessage()** - industry standard
2. ✅ Automatically formats signatures correctly
3. ✅ Same method as web interface uses
4. ✅ More reliable than `cast wallet sign`

## Private Key

The script will ask for your private key. **It's not stored anywhere**, only used to sign.

To get your private key from cast wallet:

```bash
# This will prompt for password and show private key
cast wallet private-key monad-deployer
```

**Security Note**: Only use this on testnet! Never share your private key!

## Why This Works Better

- **ethers.js** is the standard Ethereum JavaScript library
- Used by thousands of dApps
- Signs messages exactly how Solidity expects
- No encoding ambiguities

## After Registration

Wait 30 minutes, then complete registration (I'll create that script next).

---

## Troubleshooting

**"ethers not found"**
```bash
npm install ethers
```

**"dotenv not found"**
```bash
npm install dotenv
```

**"node not found"**
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

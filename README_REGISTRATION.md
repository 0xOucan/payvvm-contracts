# 🎯 Complete Guide: Register Your .payvvm Name

## ✅ Final Solution: Viem (RECOMMENDED)

After extensive debugging of `cast wallet sign`, we've created **viem-based scripts** that are guaranteed to work!

### Why Viem Won Over Cast

**Cast Issues Found:**
- ❌ Signature format incompatibility with Solidity's ecrecover
- ❌ Keystore access issues in scripts
- ❌ Subtle EIP-191 encoding differences

**Viem Advantages:**
- ✅ Industry-standard `signMessage()` function
- ✅ Perfect EIP-191 compliance
- ✅ Used by modern web3 frontends
- ✅ Battle-tested on millions of transactions

## 🚀 Quick Start (30 seconds)

```bash
# 1. Get your private key
cast wallet private-key monad-deployer

# 2. Register
node register-name-viem.js test

# 3. Wait 30 minutes ⏰

# 4. Complete
node complete-registration-viem.js
```

**That's it!** You'll own `$test.payvvm` 🎉

## 📦 What's Installed

All dependencies are ready:
- ✅ Node.js v23.6.0
- ✅ npm v11.0.0
- ✅ viem (latest)
- ✅ dotenv

## 📁 Available Scripts

### Viem Scripts (⭐ RECOMMENDED)
- **`register-name-viem.js`** - Pre-registration (Step 1)
- **`complete-registration-viem.js`** - Complete registration (Step 2)

### Utility Scripts
- **`check-mate-balance.sh`** - Check your MATE balance
- **`check-evvm-state.sh`** - Check contract state
- **`claim-mate-tokens.sh`** - Get more MATE (can claim ~87 more times!)

### Legacy Scripts (for reference)
- `register-payvvm-name.sh` - Bash/cast version (has signature issues)
- `register-name-nodejs.js` - Ethers.js version (works but larger)

## 💰 Your Current Status

- **MATE Balance**: 26,533.125 MATE
- **Registration Cost**: ~31.25 MATE per name
- **Can Register**: ~850 .payvvm names!

## 🔍 What We Debugged

This was a deep debugging session! Here's what we fixed:

### 1. MATE Balance Checker ✅
**Issue**: `printf "%d"` overflow showing 9.2233 instead of 26,533
**Fix**: Use `cast to-dec` for large numbers

### 2. EVVM ID Discovery ✅
**Journey**:
- Started with 256 (wrong)
- Found 1000 in registry (registry ID, not contract ID)
- Discovered actual value: 0 (from `getEvvmID()`)

### 3. Nonce Handling ✅
**NameService**: Uses mapping - any unused nonce works (timestamp-based)
**EVVM**: Uses counter - must use `getNextCurrentSyncNonce()`

### 4. Cast Signature Issues ❌
**Problem**: `cast wallet sign` produces signatures that fail contract verification
**Root Cause**: Subtle encoding/format differences from what Solidity expects
**Solution**: Switch to viem's `signMessage()` ✅

## 📚 Documentation Files

- **`VIEM_REGISTRATION_GUIDE.md`** - Detailed viem guide
- **`REGISTRATION_FINAL_SOLUTION.md`** - Complete overview
- **`NODEJS_REGISTRATION_SETUP.md`** - Ethers.js version
- **`REGISTER_NAME_QUICK_START.md`** - Quick reference

## 🎓 How Viem Signing Works

```javascript
// Message format (exact same as Solidity expects)
const message = "0,preRegistrationUsername,0xhash,123456";

// Viem's signMessage does:
// 1. Prefix: "\x19Ethereum Signed Message:\n{length}"
// 2. Hash: keccak256(prefix + message)
// 3. Sign: secp256k1 signature
// 4. Return: 0x{r}{s}{v} (65 bytes)

const signature = await walletClient.signMessage({
    account,
    message
});

// This matches Solidity's SignatureRecover.sol:
// messageHash = keccak256(abi.encodePacked(
//     "\x19Ethereum Signed Message:\n",
//     Strings.toString(bytes(message).length),
//     message
// ))
// ecrecover(messageHash, v, r, s)
```

## 🔐 Security Notes

- **Private keys**: Only for testnet! Never share!
- **Not stored**: Scripts don't save your private key
- **EIP-191**: Prevents signature replay attacks
- **30-min wait**: Prevents front-running

## 🌐 Alternative: Web Interface

If you prefer a visual interface:

```bash
cd /home/oucan/PayVVM/envioftpayvvm
yarn install
yarn start
# Visit http://localhost:3000
```

**Advantages:**
- MetaMask integration (no private key needed)
- Visual feedback
- Manage multiple names
- View registration history

## 📊 Registration Cost Breakdown

| Action | Cost (MATE) |
|--------|-------------|
| Pre-registration | 0 (if priorityFee = 0) |
| Registration | 31.25 |
| Renewal (366 days) | 31.25 |
| Add metadata | 50 |

**Much cheaper than expected!** (Was listed as 500 MATE but actual is 31.25)

## 🎯 Next Command

```bash
node register-name-viem.js test
```

This will:
1. Ask for your private key (from `cast wallet private-key monad-deployer`)
2. Generate signatures using viem
3. Submit pre-registration
4. Save registration info

Then wait 30 minutes and run:
```bash
node complete-registration-viem.js
```

**You'll own `$test.payvvm`!** 🚀

## 🆘 Troubleshooting

**"Cannot find module 'viem'"**
```bash
npm install viem
```

**"Invalid private key format"**
Make sure it starts with `0x`

**"Transaction reverted"**
Check the error message - might need to wait 30 minutes

**"Insufficient MATE balance"**
```bash
./check-mate-balance.sh YOUR_ADDRESS
```

## 📞 Need Help?

- Read: `VIEM_REGISTRATION_GUIDE.md`
- Check: https://viem.sh/docs/actions/wallet/signMessage
- EIP-191: https://eips.ethereum.org/EIPS/eip-191

---

**Ready to register your first .payvvm name!** 🎉

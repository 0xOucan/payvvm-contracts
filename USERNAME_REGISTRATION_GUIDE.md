# PAYVVM Username Registration Guide

## ✅ Quick Answers to Your Questions

### 1. Do we already have .payvvm?
**YES!** ✅
- Your deployed NameService contract supports it
- `.payvvm` comes from your EVVM name "PAYVVM"
- No additional contracts needed

### 2. Can everyone register .payvvm names?
**YES!** ✅
- Anyone with 500 MATE tokens can register
- Usernames are first-come, first-served
- Available to all users on Ethereum Sepolia

### 3. Can users have multiple usernames?
**YES!** ✅
- One user can own UNLIMITED usernames
- Each username costs 500 MATE
- Each username points to ONE address

```
Example:
User Address: 0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99

Can own:
  ✅ $test.payvvm
  ✅ $0xoucan.payvvm
  ✅ $alice.payvvm
  ✅ $bob.payvvm
  ... (unlimited)

Each username → Points to: 0x93d2c...Ac99
```

## 📋 Username System Overview

### Format
- **Base**: `test`, `0xoucan`, `alice` (3-20 chars, lowercase, numbers, underscore)
- **Display**: `$test.payvvm`, `$0xoucan.payvvm`
- **Stored in contract**: `test`, `0xoucan` (without $ or .payvvm)

### Pricing
- **Registration**: 500 MATE tokens
- **Duration**: 366 days
- **Renewal**: 500 MATE (extends another 366 days)
- **Metadata**: 50 MATE per entry

### Ownership Rules
```
✅ One username → One owner address
✅ One address → Multiple usernames
✅ Transferable (can be sold/traded)
✅ Renewable (before expiration)
❌ Cannot have same username twice
```

## 🚀 Registration Methods

### Method 1: Web Interface (RECOMMENDED) ⭐

**Why?** Handles all complexity automatically:
- ✅ Signature generation
- ✅ Nonce management
- ✅ Two-step commit-reveal
- ✅ User-friendly interface

**Setup:**
```bash
# 1. Configure envioftpayvvm (if not done)
cd /home/oucan/PayVVM
./setup-payvvm-nameservice.sh

# 2. Start frontend
cd envioftpayvvm
yarn start

# 3. Open browser
http://localhost:3000/nameservice

# 4. Connect wallet & register!
```

### Method 2: Command Line (ADVANCED) ⚠️

**Why difficult?**
- Requires dual signature generation (EIP-191)
- Manual nonce management
- Two-step process with 30-minute wait
- Need to construct signature messages correctly

**Scripts provided:**
```bash
# Check if username is available
./check-username.sh test

# Attempt registration (shows manual steps)
./register-username.sh test

# Check your owned usernames
./my-usernames.sh
```

**The Challenge:**

Every registration requires TWO signatures:

1. **NameService Signature** - Proves you want to register
   ```
   Message format: "functionID,address,username,nonce"
   Must sign with EIP-191 format
   ```

2. **EVVM Payment Signature** - Proves you'll pay 500 MATE
   ```
   Message format: Complex EVVM payment structure
   Must match EVVM signature requirements
   ```

**This is why the web interface is strongly recommended!**

## 📝 Registration Process (Two Steps)

### Step 1: Pre-Registration (Commit)

**Purpose**: Prevent front-running

```bash
# What happens:
1. User wants: "test"
2. Choose secret: 12345
3. Calculate hash: keccak256("test12345")
4. Submit hash to contract
5. Pay 500 MATE
6. Wait 30 minutes minimum
```

**Why 30 minutes?**
- Prevents attackers from seeing your desired username
- Gives time for blockchain confirmation
- Security feature

### Step 2: Registration (Reveal)

**Purpose**: Complete registration

```bash
# What happens:
1. After 30+ minutes, reveal:
   - Username: "test"
   - Secret: 12345
2. Contract verifies: keccak256("test12345") == stored hash
3. If matches: You own $test.payvvm for 366 days!
4. If doesn't match: Transaction fails
```

## 🔧 Helper Scripts

### Check Username Availability

```bash
chmod +x check-username.sh
./check-username.sh test

# Output:
# ✅ USERNAME AVAILABLE!  (or)
# ❌ USERNAME TAKEN
#    Owner: 0x...
```

### Register Username

```bash
chmod +x register-username.sh
./register-username.sh test

# Note: Shows manual steps needed
# Recommends using web interface instead
```

### View Your Usernames

```bash
chmod +x my-usernames.sh
./my-usernames.sh

# Shows how to query your owned usernames
# Recommends using web interface or indexer
```

## 💡 Why Web Interface Is Better

| Feature | Command Line | Web Interface |
|---------|--------------|---------------|
| Signature Generation | Manual (complex) | Automatic ✅ |
| Nonce Management | Manual tracking | Automatic ✅ |
| Two-step Process | Manual timing | Countdown timer ✅ |
| Error Handling | Debug yourself | User-friendly messages ✅ |
| View Usernames | Query events | Dashboard ✅ |
| Metadata Management | Manual calls | Visual editor ✅ |
| Renewal | Manual | Click button ✅ |

## 🎯 Recommended Workflow

### For Users (Non-Technical)

1. Wait for web interface to be built
2. Connect wallet (MetaMask, etc.)
3. Click "Register Username"
4. Follow UI prompts
5. Done!

### For Developers (You)

1. **First**: Build the web interface
   ```bash
   cd /home/oucan/PayVVM/envioftpayvvm
   # Build registration UI
   # Implement signature generation
   # Create user dashboard
   ```

2. **Then**: Test registration
   ```bash
   # Use your own web interface
   # Register: $test.payvvm, $0xoucan.payvvm
   ```

3. **Finally**: Share with users
   ```bash
   # Deploy frontend
   # Users can register easily
   ```

## 📊 Example: Multiple Usernames

### Scenario

You want to register:
- `$test.payvvm` - For testing
- `$0xoucan.payvvm` - Your personal name
- `$payvvm.payvvm` - Project name

### Process

```bash
# For each username:

1. Register $test.payvvm:
   Cost: 500 MATE
   Owner: 0x93d2c...Ac99
   Duration: 366 days

2. Register $0xoucan.payvvm:
   Cost: 500 MATE
   Owner: 0x93d2c...Ac99
   Duration: 366 days

3. Register $payvvm.payvvm:
   Cost: 500 MATE
   Owner: 0x93d2c...Ac99
   Duration: 366 days

Total Cost: 1500 MATE
All owned by: Same address
```

### Result

```
Your Address: 0x93d2c57690DB077e5d0B3112F1B255C6CB39Ac99

Owns:
├─ $test.payvvm
├─ $0xoucan.payvvm
└─ $payvvm.payvvm

Anyone can send to any of these names!
All resolve to your address: 0x93d2c...Ac99
```

## 🔐 Important Notes

### Security

- **Secret Number**: Keep it private! Anyone with your secret can't steal your username, but don't share it
- **Hash Pre-image**: The commit-reveal protects against front-running
- **Wallet Security**: Only you can register/manage your usernames

### Economics

- **Registration Fee**: Goes to Treasury & Fisher rewards
- **Expiration**: Must renew every 366 days
- **No Refunds**: Registration is final
- **Trading**: Can sell usernames on marketplace

### Technical

- **Contract Storage**: Only stores base username (no $ or .payvvm)
- **Display Format**: Frontend adds $ and .payvvm
- **Resolution**: Username → Address lookup
- **Reverse Lookup**: Address → Usernames (via indexer)

## 🚨 Common Issues

### "Username already taken"
**Solution**: Try different username or make offer to owner

### "Invalid username format"
**Rules**:
- 3-20 characters
- Lowercase only
- Letters, numbers, underscore
- No spaces or special chars

### "Insufficient MATE balance"
**Solution**: Get 500 MATE tokens from Treasury or buy from market

### "Pre-registration not found"
**Causes**:
- Haven't waited 30 minutes
- Hash doesn't match (wrong secret)
- Pre-registration expired

### "Nonce already used"
**Solution**: Use a new nonce (increment or use timestamp)

## 📚 Next Steps

1. **Make scripts executable**:
   ```bash
   chmod +x check-username.sh
   chmod +x register-username.sh
   chmod +x my-usernames.sh
   ```

2. **Test username availability**:
   ```bash
   ./check-username.sh test
   ./check-username.sh 0xoucan
   ```

3. **Build web interface** (recommended):
   ```bash
   cd /home/oucan/PayVVM/envioftpayvvm
   yarn start
   # Build registration UI
   ```

4. **Register your first username**!
   - Via web interface (when ready)
   - Or via manual contract interaction (advanced)

## 🎉 Summary

- ✅ **.payvvm is ready** - No new contracts needed
- ✅ **Everyone can register** - Open to all with 500 MATE
- ✅ **Multiple usernames** - Unlimited per user
- ✅ **Scripts provided** - Check availability, helper tools
- ✅ **Web interface recommended** - Easiest way to register

**Next**: Build the web interface for easy registration! 🚀

---

For detailed frontend setup, see: `PAYVVM_NAME_SERVICE_GUIDE.md`

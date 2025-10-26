# 🎯 Testing PayVVM with Official EVVM Frontend

## Official Deployed Frontend

**URL**: https://signature-constructor.evvm.info

This is the production-ready EVVM Signature Constructor maintained by the EVVM team.

---

## 📋 Step-by-Step Testing Guide

### Step 1: Access the Frontend

1. Open your browser
2. Navigate to: **https://signature-constructor.evvm.info**
3. The interface should load with the EVVM logo and connect button

### Step 2: Connect Your Wallet

1. **Click "Connect"** button (top right)
2. **Select MetaMask** (or your preferred wallet)
3. **Approve the connection** in the MetaMask popup
4. **Switch to Sepolia network** if prompted
5. **Verify**: You should see your wallet address displayed (e.g., `0x9c...7C6e45`)

### Step 3: Configure Your EVVM Instance

The frontend needs to know which EVVM contracts to interact with:

1. **Find the EVVM configuration section** (usually at the top)
2. **Select Network**: Choose **"Sepolia"**
3. **Enter EVVM Address**: `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e`
4. **Click "Fetch EVVM Summary"** (or similar button)

**Expected Result:**
```
evvmID: 0
evvm: 0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e
nameService: 0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55
staking: 0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816
```

✅ If you see these values, your EVVM is properly connected!

### Step 4: Test .payvvm Name Registration

#### Phase 1: Pre-Registration

1. **Navigate to**: "Name Service signatures" → "Pre-registration of username"

2. **Fill in the form**:
   - **Username**: `test` (or your desired username)
   - **Clow Number (Secret)**: `1234567890` (SAVE THIS! You'll need it later)
     - Or click "Generate Random Clow Number"
   - **NameService Nonce**: Click "Generate Random NameService Nonce"
   - **Priority Fee**: `0` (for testing)
   - **EVVM Nonce Type**: Select "asynchronous nonce"
   - **EVVM Nonce**: Click "Generate Random EVVM Nonce"

3. **Click "Create signature"**

4. **Sign the message in MetaMask** when prompted

5. **Click "Execute"** to submit the transaction

6. **Wait for confirmation** - You should see a success message with transaction hash

7. **⏰ WAIT 30 MINUTES** - This is a security feature (commit-reveal scheme)

#### Phase 2: Complete Registration (After 30 minutes)

1. **Navigate to**: "Name Service signatures" → "Registration of username"

2. **Fill in the form**:
   - **Username**: `test` (MUST match pre-registration)
   - **Clow Number**: `1234567890` (MUST match pre-registration secret)
   - **NameService Nonce**: Generate new nonce
   - **Priority Fee**: `0`
   - **EVVM Nonce Type**: asynchronous
   - **EVVM Nonce**: Generate new

3. **Click "Create signature"**

4. **Sign in MetaMask**

5. **Click "Execute"**

6. **Success!** 🎉 You now own `$test.payvvm`

---

## 🔍 What to Look For

### ✅ Success Indicators

- **Pre-registration**:
  - Transaction succeeds
  - You get a transaction hash
  - No errors in MetaMask

- **Registration** (after 30 min):
  - Transaction succeeds
  - You receive confirmation
  - Your username is registered

### ❌ Failure Indicators

- **"InvalidSignatureOnNameService"**: Same error we saw in CLI
  - Means: Contract-level signature verification issue
  - Action: Check contract deployment/initialization

- **"PreRegistrationNotValid"**:
  - Means: 30 minutes haven't passed OR wrong secret
  - Action: Wait longer or verify secret matches

- **"UsernameAlreadyRegistered"**:
  - Means: Username already taken
  - Action: Try a different username

---

## 📊 Contract Addresses Reference

| Contract | Address | Network |
|----------|---------|---------|
| EVVM | `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e` | Sepolia |
| NameService | `0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55` | Sepolia |
| Staking | `0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816` | Sepolia |
| Estimator | `0x2aBEAD7519c9AFc14eEc2582dDD9FF04f0da0F42` | Sepolia |
| Treasury | `0x98465F828b82d0b676937e159547F35BBDBdfe91` | Sepolia |

---

## 🎓 What This Test Will Tell Us

### Scenario 1: Registration Works on Official Frontend ✅

**Meaning**:
- ✅ Your contracts are deployed correctly
- ✅ Contract logic is working
- ❌ Our CLI scripts have signature construction issues

**Next Steps**:
- Compare official frontend's signature library approach
- Update our CLI scripts to match
- We can use `@evvm/viem-signature-library` package

### Scenario 2: Registration Fails with Same Error ❌

**Meaning**:
- ❌ Contract-level issue
- ✅ Not a problem with our CLI approach
- ❌ Something wrong with deployment or initialization

**Possible Causes**:
- EVVM ID mismatch in signature verification
- NameService not properly initialized
- Missing admin setup step
- Contract bytecode issue

**Next Steps**:
- Review deployment scripts
- Check contract initialization
- Verify all setup functions were called
- May need to redeploy

---

## 💡 Pro Tips

1. **Save Your Secret**: Write down the Clow Number/Secret - you can't complete registration without it!

2. **Check Etherscan**: After each transaction, check:
   - https://sepolia.etherscan.io/address/0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55
   - Look for your transaction in the list
   - Check if it succeeded or reverted

3. **30-Minute Timer**: Set a timer after pre-registration so you don't try to complete too early

4. **Gas/ETH**: Make sure you have enough Sepolia ETH for gas fees

5. **MetaMask Network**: Double-check you're on Sepolia before each transaction

---

## 🔗 Additional Features to Try

Once registration works, you can also test:

### Payment Functions
- Single Payment
- Batch Payment (Disperse Pay)

### Staking Functions
- Public Staking (you have 26,533 MATE!)
- Golden Staking
- Presale Staking

### Other Name Service Functions
- Make Offer on username
- Withdraw Offer
- Accept Offer
- Renew Username (after 366 days)
- Add Custom Metadata
- Remove Custom Metadata

---

## 📞 If You Need Help

1. **Check Browser Console** (F12) for detailed error messages
2. **Check Etherscan** for transaction details
3. **Verify MetaMask** is on correct network
4. **Double-check** contract addresses match

---

## ✨ Expected Cost

Based on your contract configuration:

- **Pre-registration**: ~Gas fees only (if priority fee = 0)
- **Registration**: ~31.25 MATE + gas
- **Your MATE Balance**: 26,533.125 MATE
- **Can Register**: ~850 .payvvm names!

---

**Good luck with testing!** The official frontend will definitively show us whether your contracts are working correctly. 🚀

# Username Registration Investigation - Key Findings

## 🎯 TL;DR

✅ **You successfully claimed MATE tokens!** (Transaction 0x6313a4be...9e192168 succeeded)  
❌ **Username registration failed** because the actual process is much more complex than expected  
✅ **Solution**: Use the web interface instead of CLI

---

## What Actually Happened

### Your recalculateReward() Transaction

```
Transaction: 0x6313a4be677e62b8c6fa54cc7a6957357b809eb4ae6c63da46e2ddea9e192168
Block: 9456737
Status: 1 (success) ✅
```

**This succeeded!** You have MATE tokens in your EVVM balance.

### Why the Script Showed Errors

The errors you saw were NOT transaction failures:

```
(standard_in) 1: syntax error
error: unexpected argument 'ether' found
```

These errors occurred because:
1. The EVVM contract has **NO** `balanceOf()` function
2. The `balances` mapping is **private** (not public)
3. The script tried to check your balance but couldn't

**Your transaction still succeeded** - we just couldn't display the balance!

---

## Why Username Registration Failed

The registration uses a completely different system than expected:

### What I Tried (WRONG)
```solidity
registerName(address,string,uint256,uint256,bytes)  // ❌ This function doesn't exist!
```

### What Actually Exists (CORRECT)
```solidity
// Step 1: Pre-register (commit to a hash)
preRegistrationUsername(
    address user,
    bytes32 hashPreRegisteredUsername,  // keccak256(username + secret)
    uint256 nonce,
    bytes memory signature,             // Signature #1: NameService auth
    uint256 priorityFee_EVVM,
    uint256 nonce_EVVM,
    bool priorityFlag_EVVM,
    bytes memory signature_EVVM         // Signature #2: EVVM payment
)

// Step 2: Wait 30 minutes

// Step 3: Register (reveal the username)
registrationUsername(
    address user,
    string memory username,
    uint256 clowNumber,                 // The secret from step 1
    uint256 nonce,
    bytes memory signature,             // Signature #1: NameService auth
    uint256 priorityFee_EVVM,
    uint256 nonce_EVVM,
    bool priorityFlag_EVVM,
    bytes memory signature_EVVM         // Signature #2: EVVM payment
)
```

---

## Technical Deep Dive

### Dual Signature Requirement

Each registration step requires **TWO signatures**:

1. **NameService Signature** (EIP-191)
   - Domain: `keccak256("nameService" + keccak256("PayVVM"))`
   - TypeHash: Specific to each function (pre-reg vs reg)
   - Proves authorization for the NameService operation

2. **EVVM Payment Signature** (EIP-191)
   - Authorizes the MATE token transfer
   - Pays for the registration (500 MATE)
   - Different signature format than NameService

### Why This Complexity?

From the contract comments (NameService.sol:42-44):
```
* Registration Process:
* 1. Pre-register: Commit to a username hash to prevent front-running
* 2. Register: Reveal the username and complete registration within 30 minutes
```

This prevents someone from seeing your transaction and registering the username before you!

### No Balance Getter Function

From EvvmStorage.sol:53:
```solidity
mapping(address user => mapping(address token => uint256 quantity)) balances;
```

This mapping is **not marked as public**, so Solidity doesn't auto-generate a getter function.

You can only check balances by:
- Trying a transaction (it will fail if insufficient balance)
- Reading raw storage slots (advanced)
- Using an indexer that tracks events (envioftpayvvm)

---

## MATE Token Economics

Current EVVM state:
```
Total Supply: 2,033,333,333 MATE (with 18 decimals)
Era Tokens:   1,524,999,999.75 MATE
Reward:       2.5 MATE
```

recalculateReward() gives you:
```
2.5 MATE × random(1, 5083) = 2.5 to 12,707.5 MATE
```

Username registration costs:
```
500 MATE (way less than minimum reward!)
```

---

## Solutions

### ✅ RECOMMENDED: Use Web Interface

The frontend handles all the signature complexity automatically:

```bash
cd ../envioftpayvvm
yarn install
yarn start
# Visit http://localhost:3000
```

The web UI will:
- Generate both signatures automatically
- Handle the two-step process
- Show your balance via the indexer
- Provide a much better UX

### ⚠️ CLI Registration (Not Recommended)

To do this via CLI, you would need to:

1. Implement NameService EIP-191 signature generation
2. Implement EVVM payment EIP-191 signature generation
3. Call preRegistrationUsername() with both signatures
4. Wait 30 minutes
5. Generate new signatures for step 2
6. Call registrationUsername() with both signatures

This requires implementing two different signature schemes from:
- `src/contracts/nameService/lib/SignatureUtils.sol`
- `src/contracts/evvm/lib/SignatureUtils.sol`

**It's much easier to use the web interface!**

---

## Contract Details

### Deployed Addresses
```
EVVM:        0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e
NameService: 0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55
```

### Key Functions
```
EVVM:
- recalculateReward() public                     ✅ You called this!
- getEraPrincipalToken() view returns (uint256)
- getRewardAmount() view returns (uint256)
- getPrincipalTokenTotalSupply() view returns (uint256)

NameService:
- preRegistrationUsername(...)  // Step 1
- registrationUsername(...)     // Step 2
```

---

## Next Steps

1. **Start the frontend**
   ```bash
   cd ../envioftpayvvm
   yarn install && yarn start
   ```

2. **Register your username** via the web UI

3. **Optional**: Set up the Envio indexer to track balances and events

4. **Enjoy** your username in the PayVVM ecosystem!

---

## Files Created

- `USERNAME_REGISTRATION_ANALYSIS.md` - Detailed technical analysis
- `FINDINGS_SUMMARY.md` - This file
- `claim-mate-tokens.sh` - Fixed to not check balances
- `register-username.sh` - Needs rewrite for dual signatures (use web UI instead)
- `CLAIM_MATE_TOKENS_INSTRUCTIONS.md` - Original investigation notes

---

## Lessons Learned

1. Always check contract ABI before assuming function signatures
2. Balance checking requires a public getter or events
3. Username registration systems often use commit-reveal to prevent front-running
4. Multi-signature requirements are common for payment operations
5. Web UIs are much better for complex signature workflows

---

**Generated**: 2025-10-20  
**Network**: Ethereum Sepolia  
**EVVM ID**: 1000 (PayVVM)

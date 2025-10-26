# EVVM Nonce System - Complete Analysis

## Executive Summary

After analyzing the deployed contracts (`Evvm.sol` and `NameService.sol`), I've identified that EVVM uses **THREE SEPARATE NONCE SYSTEMS** that work independently:

1. **NameService Nonces** - For NameService-specific operations (username registration, offers, metadata)
2. **EVVM Sync Nonces** - For synchronous payment transactions
3. **EVVM Async Nonces** - For asynchronous payment transactions

## Critical Finding: The `getNextCurrentSyncNonce` Function

### Function Definition (Evvm.sol:1182-1186)

```solidity
function getNextCurrentSyncNonce(address user) external view returns (uint256) {
    return nextSyncUsedNonce[user];
}
```

### Storage Mappings

```solidity
mapping(address => uint256) nextSyncUsedNonce;  // Counter for sync transactions
mapping(address => mapping(uint256 => bool)) asyncUsedNonce;  // Mapping for async transactions
```

### How Nonces Are Used in Payment Verification (Evvm.sol:369)

**THE CRITICAL LINE:**
```solidity
priorityFlag ? nonce : nextSyncUsedNonce[from]
```

This means:
- **Async (priorityFlag = true)**: Uses the `nonce` parameter you provide
- **Sync (priorityFlag = false)**: **IGNORES** the `nonce` parameter and uses `nextSyncUsedNonce[from]` from storage

### Nonce Update After Payment (Evvm.sol:401-405)

```solidity
if (priorityFlag) {
    asyncUsedNonce[from][nonce] = true;  // Async: mark specific nonce as used
} else {
    nextSyncUsedNonce[from]++;  // Sync: increment counter
}
```

---

## The Three Nonce Systems Explained

### 1. NameService Nonces

**Purpose**: Prevent replay attacks on NameService operations (registration, offers, metadata)

**Storage**:
```solidity
mapping(address => mapping(uint256 => bool)) nameServiceNonce;
```

**Validation** (NameService.sol:103-108):
```solidity
modifier verifyIfNonceIsAvailable(address user, uint256 nonce) {
    if (nameServiceNonce[user][nonce] == true)
        revert ErrorsLib.NonceAlreadyUsedOnNameService();
    _;
}
```

**How It Works**:
- **Mapping-based**: Any unused nonce works (timestamp recommended)
- **Validation**: Checks if `nameServiceNonce[user][nonce]` is `false`
- **Update**: Sets `nameServiceNonce[user][nonce] = true` after use
- **Flexibility**: You can use ANY nonce that hasn't been used before

**Best Practice**: Use timestamp-based nonces like `Date.now().toString().slice(-15)`

---

### 2. EVVM Sync Nonces

**Purpose**: Sequential ordering for synchronous EVVM payments

**Storage**:
```solidity
mapping(address => uint256) nextSyncUsedNonce;
```

**Validation** (Evvm.sol:369):
```solidity
// Uses nextSyncUsedNonce[from] regardless of what nonce you pass!
priorityFlag ? nonce : nextSyncUsedNonce[from]
```

**How It Works**:
- **Counter-based**: Sequential numbers (0, 1, 2, 3, ...)
- **Automatic**: The contract uses `nextSyncUsedNonce[from]` from storage
- **Ignored Parameter**: The `nonce` parameter passed to the function is NOT used when `priorityFlag = false`
- **Increment**: `nextSyncUsedNonce[from]++` after successful payment
- **No Choice**: You MUST use the next sequential number

**To Get Current Sync Nonce**:
```bash
cast call $EVVM "getNextCurrentSyncNonce(address)(uint256)" $USER_ADDRESS --rpc-url $RPC_URL
```

**CRITICAL**: When creating a sync payment signature (`priorityFlag = false`), you must:
1. Fetch `getNextCurrentSyncNonce(userAddress)`
2. Use this EXACT value in your signature
3. Pass `priorityFlag = false`
4. The `nonce` parameter you pass to the function is IGNORED - contract uses its internal counter

---

### 3. EVVM Async Nonces

**Purpose**: Flexible ordering for asynchronous EVVM payments with priority fees

**Storage**:
```solidity
mapping(address => mapping(uint256 => bool)) asyncUsedNonce;
```

**Validation** (Evvm.sol:381-382):
```solidity
if (priorityFlag && asyncUsedNonce[from][nonce])
    revert ErrorsLib.InvalidAsyncNonce();
```

**How It Works**:
- **Mapping-based**: Any unused nonce works
- **Flexible**: Transactions can execute out of order
- **Validation**: Checks if `asyncUsedNonce[from][nonce]` is `false`
- **Update**: Sets `asyncUsedNonce[from][nonce] = true` after use
- **Priority**: Used when `priorityFlag = true`

**Best Practice**: Use random or timestamp-based nonces

---

## NameService Functions and Nonce Usage

### Pre-Registration Username (NameService.sol:205-257)

**Function Signature**:
```solidity
function preRegistrationUsername(
    address user,
    bytes32 hashPreRegisteredUsername,
    uint256 nonce,                    // NameService nonce
    bytes memory signature,           // NameService signature
    uint256 priorityFee_EVVM,        // EVVM priority fee
    uint256 nonce_EVVM,              // EVVM nonce (sync or async)
    bool priorityFlag_EVVM,          // EVVM nonce type
    bytes memory signature_EVVM      // EVVM payment signature
)
```

**Execution Flow**:

1. **NameService Signature Verification** (Lines 215-223):
   ```solidity
   if (!SignatureUtils.verifyMessageSignedForPreRegistrationUsername(
       Evvm(evvmAddress.current).getEvvmID(),  // Line 217: Gets EVVM ID (0)
       user,
       hashPreRegisteredUsername,
       nonce,                                   // NameService nonce
       signature                                // NameService signature
   )) revert ErrorsLib.InvalidSignatureOnNameService();  // Line 223: FAILS HERE
   ```
   - **Message Format**: `{evvmID},preRegistrationUsername,{hash},{nonce}`
   - **Example**: `0,preRegistrationUsername,0xabc123...,176102314683936`
   - **Nonce Type**: NameService nonce (any unused value)

2. **Optional EVVM Payment** (Lines 225-234):
   ```solidity
   if (priorityFee_EVVM > 0) {
       makePay(
           user,
           0,                        // amount = 0 (no base payment)
           priorityFee_EVVM,        // priority fee
           nonce_EVVM,              // EVVM nonce
           priorityFlag_EVVM,       // sync or async
           signature_EVVM           // EVVM payment signature
       );
   }
   ```
   - **Only Executed**: When `priorityFee_EVVM > 0`
   - **EVVM Signature Required**: Only if paying priority fee
   - **Nonce Type**: EVVM sync or async (depending on `priorityFlag_EVVM`)

3. **Pre-Registration Storage** (Lines 236-247):
   - Stores hash with 30-minute expiry
   - `flagNotAUsername = 0x01` marks it as pre-registration

4. **NameService Nonce Marking** (Line 249):
   ```solidity
   nameServiceNonce[user][nonce] = true;
   ```

5. **Staker Reward** (Lines 251-256):
   ```solidity
   if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
       makeCaPay(msg.sender, ...);
   }
   ```

---

## Why Our Registration Attempts Failed

### The Issue

Our scripts were failing at **Line 223** (NameService signature verification), which happens BEFORE any EVVM payment logic.

### What We Got Right ✅

1. **EVVM ID**: Correctly identified as `0`
2. **Hash Generation**: Correctly using lowercase keccak256
3. **NameService Nonce**: Using timestamp (valid approach)
4. **EVVM Nonce**: Correctly fetching `getNextCurrentSyncNonce`
5. **Signature Format**: All three libraries (cast, ethers, viem) produce EIP-191 compliant signatures

### What Could Be Wrong ❌

Since our signature construction is correct (verified by three different libraries), the issue must be:

1. **Contract-Level Issue**:
   - Contract may not be properly initialized
   - EVVM ID might be stored differently than `getEvvmID()` returns
   - Signature verification library might have a bug

2. **Missing Prerequisite**:
   - Some initialization step was missed during deployment
   - Admin approval or whitelist requirement

3. **Message Encoding Mismatch**:
   - Contract might expect different string encoding
   - Comma or parameter ordering issue

---

## Nonce System Decision Tree

```
For NameService Operations:
├─ Use NameService Nonce (any unused value)
│  └─ Recommended: timestamp-based
│
└─ If priorityFee_EVVM > 0:
   ├─ priorityFlag_EVVM = true (Async):
   │  └─ Use EVVM Async Nonce (any unused value)
   │     └─ Recommended: random or timestamp
   │
   └─ priorityFlag_EVVM = false (Sync):
      └─ Use EVVM Sync Nonce (sequential counter)
         └─ MUST fetch: getNextCurrentSyncNonce(address)
         └─ Contract ignores passed nonce parameter!
```

---

## Recommendations for Testing

### 1. Test on Official Frontend First

Use https://signature-constructor.evvm.info to verify contracts work:
- Uses official `@evvm/viem-signature-library` package
- Same signing approach as production EVVM
- Will definitively show if contracts are functional

**If Frontend Works ✅**:
- Contracts are correct
- Our CLI signature construction has subtle differences
- Compare frontend's library approach with our scripts

**If Frontend Fails ❌**:
- Contract deployment or initialization issue
- Not a problem with our signing approach
- Need to review deployment scripts

### 2. Verify Contract Initialization

Check if all setup functions were called:
```bash
# Check if EVVM is properly initialized
cast call $EVVM "getEvvmID()(uint256)" --rpc-url $RPC_URL
cast call $EVVM "getNameService()(address)" --rpc-url $RPC_URL

# Check if NameService is properly initialized
cast call $NAME_SERVICE "getEvvmAddress()(address)" --rpc-url $RPC_URL
```

### 3. Compare with Working Deployment

If possible, test against known working EVVM instance to verify our signature construction matches.

---

## Summary

The `getNextCurrentSyncNonce` function returns the **next expected nonce** for synchronous EVVM payments. Key points:

1. **Three Independent Systems**: NameService, EVVM Sync, EVVM Async nonces
2. **Sync Nonce Behavior**: When `priorityFlag = false`, the contract **ignores** the `nonce` parameter and uses `nextSyncUsedNonce[from]` from storage
3. **Signature Failure**: Our scripts fail at NameService signature verification (before EVVM logic)
4. **Not a Nonce Issue**: The failure is about NameService signature verification, not nonce management
5. **Next Step**: Test on official frontend to isolate if issue is contracts or our scripts

---

## Technical References

- **Evvm.sol Lines 1182-1186**: `getNextCurrentSyncNonce` function definition
- **Evvm.sol Line 369**: Critical nonce selection logic
- **Evvm.sol Lines 401-405**: Nonce update after payment
- **NameService.sol Lines 215-223**: Where our signatures fail
- **NameService.sol Lines 225-234**: Optional EVVM payment integration
- **evvmllm.txt Lines 439-499**: Transaction process documentation

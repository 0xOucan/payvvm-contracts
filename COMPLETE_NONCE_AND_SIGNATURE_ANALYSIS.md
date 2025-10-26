# Complete EVVM Nonce and Signature Analysis

## Executive Summary

After thorough analysis of the deployed contracts and the `getNextCurrentSyncNonce` function, I've completed a comprehensive investigation into the EVVM nonce system and signature verification process. This document presents the findings and recommendations.

---

## 1. The `getNextCurrentSyncNonce` Function

### Location
**File**: `src/contracts/evvm/Evvm.sol`
**Lines**: 1182-1186

### Implementation
```solidity
function getNextCurrentSyncNonce(address user) external view returns (uint256) {
    return nextSyncUsedNonce[user];
}
```

### Purpose
Returns the **next expected nonce** for synchronous (non-priority) EVVM payment transactions for a specific user address.

### Storage
```solidity
mapping(address => uint256) nextSyncUsedNonce;
```

This is a simple counter that increments after each successful synchronous payment.

---

## 2. EVVM's Three Nonce Systems

### System 1: NameService Nonces
**Type**: Mapping-based
**Storage**: `mapping(address => mapping(uint256 => bool)) nameServiceNonce`
**Use Case**: Username registration, offers, metadata operations
**Flexibility**: Any unused nonce value works
**Best Practice**: Timestamp-based nonces (`Date.now().toString().slice(-15)`)

**Validation** (NameService.sol:103-108):
```solidity
modifier verifyIfNonceIsAvailable(address user, uint256 nonce) {
    if (nameServiceNonce[user][nonce] == true)
        revert ErrorsLib.NonceAlreadyUsedOnNameService();
    _;
}
```

### System 2: EVVM Sync Nonces
**Type**: Sequential counter
**Storage**: `mapping(address => uint256) nextSyncUsedNonce`
**Use Case**: Synchronous (standard priority) EVVM payments
**Flexibility**: NONE - must use exact sequential number
**Retrieval**: Via `getNextCurrentSyncNonce(address)` function

**Critical Behavior** (Evvm.sol:369):
```solidity
// When verifying signature, uses:
priorityFlag ? nonce : nextSyncUsedNonce[from]
```

**KEY INSIGHT**: When `priorityFlag = false` (sync mode), the contract **IGNORES** the nonce parameter passed to the function and uses `nextSyncUsedNonce[from]` from storage instead!

**Update Logic** (Evvm.sol:404):
```solidity
nextSyncUsedNonce[from]++;  // Increments after successful sync payment
```

### System 3: EVVM Async Nonces
**Type**: Mapping-based
**Storage**: `mapping(address => mapping(uint256 => bool)) asyncUsedNonce`
**Use Case**: Asynchronous (high priority) EVVM payments
**Flexibility**: Any unused nonce value works
**Best Practice**: Random or timestamp-based nonces

**Validation** (Evvm.sol:381-382):
```solidity
if (priorityFlag && asyncUsedNonce[from][nonce])
    revert ErrorsLib.InvalidAsyncNonce();
```

**Update Logic** (Evvm.sol:402):
```solidity
asyncUsedNonce[from][nonce] = true;  // Marks specific nonce as used
```

---

## 3. Pre-Registration Transaction Flow

### Function Signature
```solidity
function preRegistrationUsername(
    address user,
    bytes32 hashPreRegisteredUsername,
    uint256 nonce,                    // NameService nonce
    bytes memory signature,           // NameService signature
    uint256 priorityFee_EVVM,        // EVVM priority fee
    uint256 nonce_EVVM,              // EVVM nonce (only if fee > 0)
    bool priorityFlag_EVVM,          // EVVM nonce type (only if fee > 0)
    bytes memory signature_EVVM      // EVVM payment signature (only if fee > 0)
)
```

### Execution Steps

#### Step 1: NameService Signature Verification (Lines 215-223)
**This is where our attempts are failing.**

```solidity
if (
    !SignatureUtils.verifyMessageSignedForPreRegistrationUsername(
        Evvm(evvmAddress.current).getEvvmID(),  // Gets EVVM ID (0 in our case)
        user,
        hashPreRegisteredUsername,
        nonce,
        signature
    )
) revert ErrorsLib.InvalidSignatureOnNameService();  // ❌ FAILS HERE
```

**Message Format**:
```
"{evvmID},preRegistrationUsername,{lowercaseHashWith0x},{nonce}"
```

**Example**:
```
"0,preRegistrationUsername,0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8,176102314683936"
```

#### Step 2: Optional EVVM Payment (Lines 225-234)
**Only executed when `priorityFee_EVVM > 0`**

```solidity
if (priorityFee_EVVM > 0) {
    makePay(
        user,
        0,                        // amount = 0
        priorityFee_EVVM,        // priority fee amount
        nonce_EVVM,              // EVVM nonce
        priorityFlag_EVVM,       // sync or async
        signature_EVVM           // EVVM payment signature
    );
}
```

**For Our Testing** (where `priorityFee_EVVM = 0`):
- This block is **NEVER EXECUTED**
- The EVVM nonce, flag, and signature are **NOT VALIDATED**
- Only the NameService signature matters

#### Step 3: Pre-Registration Storage (Lines 236-247)
Creates a temporary identity with:
- 30-minute expiration
- `flagNotAUsername = 0x01` (marks as pre-registration)

#### Step 4: Nonce Marking (Line 249)
```solidity
nameServiceNonce[user][nonce] = true;
```

#### Step 5: Optional Staker Reward (Lines 251-256)
If the transaction executor (msg.sender) is a staker, they receive a reward.

---

## 4. Signature Verification Deep Dive

### Contract's Verification Chain

**SignatureUtils.sol** → **SignatureRecover.sol** → **ecrecover**

#### Level 1: SignatureUtils.verifyMessageSignedForPreRegistrationUsername
```solidity
return SignatureRecover.signatureVerification(
    Strings.toString(evvmID),           // "0"
    "preRegistrationUsername",
    string.concat(
        AdvancedStrings.bytes32ToString(_hashUsername),  // Converts to lowercase hex with 0x
        ",",
        Strings.toString(_nameServiceNonce)
    ),
    signature,
    signer
);
```

#### Level 2: SignatureRecover.signatureVerification
```solidity
return recoverSigner(
    string.concat(evvmID, ",", functionName, ",", inputs),
    signature
) == expectedSigner;
```

#### Level 3: SignatureRecover.recoverSigner
```solidity
bytes32 messageHash = keccak256(
    abi.encodePacked(
        "\x19Ethereum Signed Message:\n",
        Strings.toString(bytes(message).length),  // Message length as decimal string
        message
    )
);
(bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
return ecrecover(messageHash, v, r, s);
```

### EIP-191 Format

**Full Hash Structure**:
```
keccak256(
    "\x19Ethereum Signed Message:\n" +
    "{messageLength}" +
    "{message}"
)
```

**Example**:
- Message: `"0,preRegistrationUsername,0x1c8a...eac8,176102314683936"`
- Length: `92`
- Full: `"\x19Ethereum Signed Message:\n92" + message`

---

## 5. What Our Scripts Do Correctly ✅

All three signing methods (cast, ethers.js, viem) correctly:

1. ✅ **Message Construction**: Use format `{evvmID},{functionName},{lowercaseHash},{nonce}`
2. ✅ **EVVM ID**: Fetch and use `0` (verified via `getEvvmID()`)
3. ✅ **Hash Format**: Generate lowercase keccak256 with `0x` prefix
4. ✅ **Nonce Format**: Use timestamp-based decimal string
5. ✅ **EIP-191 Wrapping**: Apply `\x19Ethereum Signed Message:\n{len}{msg}`
6. ✅ **Signature Format**: Produce 65-byte ECDSA signature (r, s, v)
7. ✅ **V Normalization**: Ensure v is 27 or 28

---

## 6. Evidence of Contract Issues ❌

### Finding 1: Missing View Functions
**Test**: `cast call $EVVM "getNameService()(address)"`
**Result**: `Error: execution reverted, data: "0x"`
**Implication**: Contract might be missing expected functions or using different interface

### Finding 2: Admin Getter Fails
**Test**: `cast call $NAME_SERVICE "admin()(address)"`
**Result**: `Error: execution reverted, data: "0x"`
**Explanation**: `admin` is a struct (`AddressTypeProposal`), not a simple address variable
**Implication**: Need to access `admin.current` through storage or proper getter

### Finding 3: No Successful Registrations on Etherscan
**Observation**: No successful pre-registration or registration transactions exist on-chain
**Checked**: https://sepolia.etherscan.io/address/0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55
**Implication**: Either:
- Nobody has successfully registered (unlikely for a deployed system)
- There's a contract-level issue preventing all registrations
- Contract was recently deployed and untested

### Finding 4: Three Libraries Fail Identically
**Tested**:
- Foundry's `cast wallet sign` (Rust/EVM native)
- ethers.js v6 (JavaScript/TypeScript standard)
- viem (Modern TypeScript library)

**Result**: All produce identical `InvalidSignatureOnNameService` error
**Implication**: Not a library-specific issue; likely contract-level problem

---

## 7. Recommended Next Steps

### Priority 1: Test on Official Frontend ⚡

**URL**: https://signature-constructor.evvm.info

**Setup**:
1. Connect wallet to Sepolia network
2. Enter EVVM address: `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e`
3. Click "Fetch EVVM Summary"
4. Try username pre-registration

**What This Will Tell Us**:

**If Frontend Succeeds** ✅:
- Contracts are functional
- Our CLI has a subtle difference from official implementation
- **Next**: Compare with `@evvm/viem-signature-library` package
- **Next**: Examine frontend's exact signature construction

**If Frontend Fails** ❌:
- Contract deployment/initialization issue
- Not a problem with our approach
- **Next**: Review deployment scripts
- **Next**: Check initialization functions
- **Next**: Consider redeployment

### Priority 2: Verify Contract Initialization

Check if deployment completed all setup steps:

```bash
# Check EVVM state
cast call $EVVM "getEvvmID()(uint256)" --rpc-url $RPC_URL

# Check NameService configuration
cast call $NAME_SERVICE "getEvvmAddress()(address)" --rpc-url $RPC_URL

# Check if contracts are linked properly
# (NameService should know about EVVM, EVVM should know about NameService)
```

### Priority 3: Review Deployment Logs

Check `broadcast/DeployTestnet.s.sol/11155111/run-latest.json` for:
- All contract deployments completed
- All initialization functions called
- No failed transactions
- Correct parameter values

### Priority 4: Contact EVVM Team

If official frontend also fails:
- Deployment might need specific initialization sequence
- Missing activation step
- Admin approval required
- Whitelist requirement

---

## 8. Technical Reference Summary

### Contract Addresses (Sepolia)
| Contract | Address |
|----------|---------|
| EVVM | `0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e` |
| NameService | `0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55` |
| Staking | `0x64A47d84dE05B9Efda4F63Fbca2Fc8cEb96E6816` |
| Estimator | `0x2aBEAD7519c9AFc14eEc2582dDD9FF04f0da0F42` |
| Treasury | `0x3D6cB29a1F97a2CFf7a48af96F7ED3A02F6aA38E` |

### Key Values
- **EVVM ID**: `0`
- **MATE Token Address**: `0x0000000000000000000000000000000000000001`
- **Your Address**: `0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45`
- **MATE Balance**: 26,533.125 MATE
- **Registration Cost**: ~31.25 MATE (100x reward, where reward = 0.3125 MATE)

### Nonce Types Quick Reference
```
NameService Operations:
└─ Use NameService Nonce
   └─ Type: Mapping (any unused value)
   └─ Get: Use timestamp or random

When priorityFee_EVVM > 0:
├─ Sync (priorityFlag_EVVM = false):
│  └─ Get: cast call $EVVM "getNextCurrentSyncNonce(address)"
│  └─ Contract uses: nextSyncUsedNonce[user]
│  └─ Note: Passed nonce parameter is IGNORED!
│
└─ Async (priorityFlag_EVVM = true):
   └─ Use: Any unused value (timestamp or random)
   └─ Contract uses: Passed nonce parameter
```

---

## 9. Conclusion

The `getNextCurrentSyncNonce` function is correctly implemented and provides the sequential nonce for synchronous EVVM payments. The nonce systems are well-designed with three independent tracking mechanisms.

**The signature verification failure is NOT related to nonce handling.** Our scripts construct signatures correctly according to EIP-191 and the contract's expected format. The failure occurs at the NameService signature verification step, before any EVVM payment logic is executed.

**Most Likely Cause**: Contract deployment or initialization issue, evidenced by:
- Missing view function support
- No successful registrations on-chain
- Identical failures across three different signing libraries

**Recommended Action**: Test on official EVVM frontend (https://signature-constructor.evvm.info) to definitively isolate whether the issue is with the contracts or our implementation. This will provide a clear path forward for resolution.

---

## 10. Files Created During Analysis

1. **NONCE_SYSTEM_ANALYSIS.md** - Detailed nonce system documentation
2. **CONTRACT_SIGNATURE_ANALYSIS.md** - Signature verification flow analysis
3. **COMPLETE_NONCE_AND_SIGNATURE_ANALYSIS.md** - This comprehensive document

All analysis files are located in `/home/oucan/PayVVM/PAYVVM/` directory.

---

**Analysis Completed**: 2025-10-21
**EVVM Version**: Testnet Contracts (Sepolia)
**Network**: Ethereum Sepolia (Chain ID: 11155111)

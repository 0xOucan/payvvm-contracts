# 🚀 Register .payvvm Names with Viem

Using **viem.sh** - the modern, lightweight, and type-safe Ethereum library.

## Why Viem?

- ✅ **Modern & Fast** - Built for performance
- ✅ **Type-Safe** - Full TypeScript support
- ✅ **Lightweight** - Smaller bundle size than ethers
- ✅ **EIP-191 Compliant** - `signMessage()` works perfectly
- ✅ **Industry Standard** - Used by latest dApps

**From viem.sh docs:**
> "Viem provides low-level stateless primitives for interacting with Ethereum"

## Quick Start

### Step 1: Get Your Private Key

```bash
cast wallet private-key monad-deployer
# Enter password, copy the output (starts with 0x)
```

⚠️ **Testnet only!** Never share private keys!

### Step 2: Register Username

```bash
node register-name-viem.js test
# or
./register-name-viem.js test
```

**What happens:**
1. Asks for your private key (not stored)
2. Creates viem account using `privateKeyToAccount()`
3. Signs message with `walletClient.signMessage()`
4. Submits pre-registration transaction
5. Saves info to `.registration-pending`

### Step 3: Wait 30 Minutes ⏰

Anti-front-running security feature.

### Step 4: Complete Registration

```bash
node complete-registration-viem.js
# Auto-loads from .registration-pending
```

**Done!** You own `$test.payvvm` 🎉

## How Viem Signing Works

Based on [viem.sh/docs/actions/wallet/signMessage](https://viem.sh/docs/actions/wallet/signMessage):

```javascript
// Viem's signMessage automatically:
// 1. Prefixes with "\x19Ethereum Signed Message:\n{length}"
// 2. Hashes the message
// 3. Signs with your private key
// 4. Returns signature in standard format (r, s, v)

const signature = await walletClient.signMessage({
    account,
    message: '0,preRegistrationUsername,0x...,123456'
});
```

This is **exactly** what Solidity's `ecrecover` expects!

## Key Features

### 1. Account Creation
```javascript
import { privateKeyToAccount } from 'viem/accounts';
const account = privateKeyToAccount('0x...');
```

### 2. Public Client (Read)
```javascript
const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(RPC_URL)
});

const evvmId = await publicClient.readContract({
    address: EVVM_ADDRESS,
    abi: [...],
    functionName: 'getEvvmID'
});
```

### 3. Wallet Client (Write)
```javascript
const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(RPC_URL)
});

const txHash = await walletClient.writeContract({
    address: NAME_SERVICE_ADDRESS,
    abi: [...],
    functionName: 'preRegistrationUsername',
    args: [...]
});
```

### 4. Transaction Receipt
```javascript
const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash
});
```

## Comparison: Viem vs Cast vs Ethers

| Feature | Viem | Cast | Ethers.js |
|---------|------|------|-----------|
| **Signature Format** | ✅ Perfect | ❌ Issues | ✅ Good |
| **Bundle Size** | 🟢 Small | N/A | 🟡 Large |
| **Type Safety** | ✅ Full TS | ❌ CLI | ✅ Good |
| **Modern API** | ✅ Yes | ❌ CLI | 🟡 Older |
| **Performance** | 🟢 Fast | 🟢 Fast | 🟡 Slower |
| **Ease of Use** | ✅ Clean | ❌ Complex | ✅ Good |

## Your Status

- **MATE Balance**: 26,533.125 MATE
- **Registration Cost**: ~31.25 MATE
- **Can Register**: ~850 names!

## Script Details

### register-name-viem.js

**What it does:**
1. Creates account from private key
2. Reads EVVM ID (0)
3. Generates secret & hash
4. Gets nonces (NameService: timestamp, EVVM: counter)
5. Signs message: `"0,preRegistrationUsername,{hash},{nonce}"`
6. Submits transaction
7. Saves registration data

### complete-registration-viem.js

**What it does:**
1. Loads username & secret
2. Signs message: `"0,registrationUsername,{username},{secret},{nonce}"`
3. Completes registration
4. You own the name!

## Error Handling

Viem provides detailed error messages:

```javascript
if (error.data?.errorName) {
    console.error(`Contract error: ${error.data.errorName}`);
}
```

Common errors:
- **InvalidSignatureOnNameService** - Signature mismatch (shouldn't happen with viem!)
- **PreRegistrationNotValid** - Wait time not met or wrong secret
- **UsernameAlreadyRegistered** - Name already taken

## Advanced: Using with TypeScript

```typescript
import { createPublicClient, createWalletClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';

// Full type safety!
const account = privateKeyToAccount('0x...' as `0x${string}`);
```

## Resources

- **Viem Docs**: https://viem.sh
- **Sign Message**: https://viem.sh/docs/actions/wallet/signMessage
- **EIP-191**: https://eips.ethereum.org/EIPS/eip-191
- **EVVM Process**: https://www.evvm.info/docs/ProcessOfATransaction

## Next Steps

```bash
# Register your first .payvvm name!
node register-name-viem.js test
```

**This will work!** Viem's `signMessage()` is battle-tested and EIP-191 compliant. 🚀

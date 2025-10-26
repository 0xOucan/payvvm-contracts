## Manual Signature Testing

Since `cast wallet sign` works when run interactively but not in scripts, let's test manually:

### Step 1: Generate the Message

Run this to get the exact message:

```bash
./register-payvvm-name.sh test monad-deployer
```

It will show you:
- The hash
- The nonce
- The message to sign

### Step 2: Copy the Signature

When the script prompts you to sign, it generates a signature. **Copy that signature!**

From your last run:
```
Message: 0,preRegistrationUsername,0xc9758e584bad0b06282239f3ea987ac0ab40dd66714bf46087d4ce35f894faad,176102314683936
Signature: 0x0cc607380e1529461091311472f80860e9f9a396ec3389559785f318452e845d5b7b55282e25119d5a6504671af2c7149cccbc54266712c95ea7ddfc441de6da1c
```

### Step 3: Test Signature Locally

```bash
cast wallet verify \
  "0,preRegistrationUsername,0xc9758e584bad0b06282239f3ea987ac0ab40dd66714bf46087d4ce35f894faad,176102314683936" \
  "0x0cc607380e1529461091311472f80860e9f9a396ec3389559785f318452e845d5b7b55282e45d5b7b55282e25119d5a6504671af2c7149cccbc54266712c95ea7ddfc441de6da1c" \
  --address 0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45
```

This will tell us if `cast` itself can verify the signature.

### Step 4: Decode the Signature Components

```bash
# Extract r, s, v from the signature
SIG="0x0cc607380e1529461091311472f80860e9f9a396ec3389559785f318452e845d5b7b55282e25119d5a6504671af2c7149cccbc54266712c95ea7ddfc441de6da1c"

# r = first 32 bytes (64 hex chars after 0x)
R=0x${SIG:2:64}
# s = next 32 bytes
S=0x${SIG:66:64}
# v = last byte
V=0x${SIG:130:2}

echo "r: $R"
echo "s: $S"
echo "v: $V"
```

### Step 5: Check V Value

The v value should be 27 or 28 (or 0 or 1 in some formats).

```bash
cast to-dec $V
```

If it's 0 or 1, the contract might expect 27 or 28.

---

## The Real Issue Might Be...

Looking at the error pattern, I suspect one of these:

1. **V value format** - Contract expects v as 27/28, cast might return 0/1
2. **Signature packing** - The signature bytes might need to be in a different order
3. **Message casing** - Even though hash is lowercase, maybe something else needs adjustment

Let's test these theories!

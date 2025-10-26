# Quick Start: Register a .payvvm Name

## You Have: 26,533 MATE tokens ✅
## You Need: 500 MATE tokens per name ✅

---

## Option 1: Simple CLI Method (2 Steps) ⭐ RECOMMENDED FOR CLI

### Step 1: Start Registration
```bash
cd /home/oucan/PayVVM/PAYVVM
./register-payvvm-name.sh YOUR_USERNAME monad-deployer
```

**Example:**
```bash
./register-payvvm-name.sh test monad-deployer
# or
./register-payvvm-name.sh 0xoucan monad-deployer
```

**What happens:**
- Costs 500 MATE
- Creates a secret hash
- Waits 30 minutes (anti-front-running protection)
- Saves registration info to `.registration-pending`

### Step 2: Complete Registration (After 30 Minutes)
```bash
./complete-registration.sh
```

**Or manually:**
```bash
./complete-registration.sh YOUR_USERNAME SECRET monad-deployer
```

**What happens:**
- Verifies the secret matches
- Completes registration
- You own `$YOUR_USERNAME.payvvm` for 366 days!

---

## Option 2: Web Interface (Easiest, No Waiting) 🌐

```bash
cd /home/oucan/PayVVM/envioftpayvvm
yarn install
yarn start
```

Then visit: `http://localhost:3000/nameservice`

**Advantages:**
- Visual interface
- Automatic signature handling
- No manual waiting
- See all your usernames
- Manage metadata easily

---

## Username Rules

✅ **Allowed:**
- 3-20 characters
- Lowercase letters (a-z)
- Numbers (0-9)
- Underscore (_)

❌ **Not Allowed:**
- Uppercase letters
- Spaces
- Special characters (except _)
- Less than 3 or more than 20 chars

**Examples:**
- ✅ `test`
- ✅ `0xoucan`
- ✅ `my_name_123`
- ❌ `Test` (uppercase)
- ❌ `my-name` (dash not allowed)
- ❌ `ab` (too short)

---

## Check Username Availability

```bash
./check-username.sh test
```

---

## View Your Usernames

```bash
./my-usernames.sh
```

---

## Cost Breakdown

| Action | Cost | Your Balance |
|--------|------|-------------|
| Register 1 name | 500 MATE | 26,533 MATE ✅ |
| Register 10 names | 5,000 MATE | 26,533 MATE ✅ |
| Register 50 names | 25,000 MATE | 26,533 MATE ✅ |
| Renew (366 days) | 500 MATE | - |
| Add metadata | 50 MATE | - |

**You can register up to 53 names with your current balance!**

---

## Why 30 Minute Wait?

**Security Feature:**
- Prevents front-running attacks
- Step 1: You commit to a hash (attackers don't know what name you want)
- Wait 30 minutes (gives blockchain time to confirm)
- Step 2: You reveal the actual username

Without this, someone monitoring transactions could see your desired username and register it before you!

---

## Troubleshooting

### "Username already taken"
Try a different username or check with:
```bash
./check-username.sh YOUR_USERNAME
```

### "Insufficient MATE balance"
You have 26,533 MATE, should be plenty! If it fails, run:
```bash
./check-mate-balance.sh YOUR_ADDRESS
```

### "Wait 30 minutes"
The pre-registration requires a 30-minute waiting period. Use:
```bash
./complete-registration.sh
```
It will tell you how many minutes remain.

### "Nonce already used"
This means a transaction with that nonce was already sent. The script auto-fetches the latest nonce, so this shouldn't happen. If it does, wait a few blocks and try again.

---

## Quick Example

```bash
# Register "test.payvvm"
./register-payvvm-name.sh test monad-deployer

# Wait 30 minutes... ☕

# Complete registration
./complete-registration.sh

# Check it worked
./check-username.sh test

# Should show:
# Owner: 0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45 (YOU!)
```

---

## Multiple Usernames

You can own unlimited usernames! Each costs 500 MATE.

```bash
# Register your first name
./register-payvvm-name.sh alice monad-deployer
# Wait 30 min...
./complete-registration.sh

# Register your second name
./register-payvvm-name.sh bob monad-deployer
# Wait 30 min...
./complete-registration.sh

# Now you own both $alice.payvvm AND $bob.payvvm!
```

---

## Next Steps

1. **Choose a username** (3-20 chars, lowercase, numbers, underscore)
2. **Check availability**: `./check-username.sh YOUR_USERNAME`
3. **Register**: `./register-payvvm-name.sh YOUR_USERNAME monad-deployer`
4. **Wait 30 minutes** ⏰
5. **Complete**: `./complete-registration.sh`
6. **Enjoy** your new .payvvm name! 🎉

---

## Need Help?

- Check the full guide: `cat USERNAME_REGISTRATION_GUIDE.md`
- View your MATE balance: `./check-mate-balance.sh YOUR_ADDRESS`
- Check EVVM state: `./check-evvm-state.sh`
- Get more MATE: `./claim-mate-tokens.sh` (can claim ~87 more times!)

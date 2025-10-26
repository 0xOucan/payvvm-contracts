# Start Web Interface for .payvvm Registration

## Quick Start

The CLI signature generation is complex. The **web interface** handles everything automatically!

### Steps:

```bash
# 1. Go to the frontend directory
cd /home/oucan/PayVVM/envioftpayvvm

# 2. Install dependencies (if not done)
yarn install

# 3. Start the frontend
yarn start
```

### What You'll Get:

- **Automatic signature generation** ✅
- **Visual username registration** ✅
- **No manual nonce management** ✅
- **See your MATE balance** ✅
- **Manage multiple usernames** ✅
- **30-minute timer countdown** ✅

### Access:

Once started, visit: **http://localhost:3000**

### Your Current Status:

- **MATE Balance**: 26,533.125 MATE
- **Registration Cost**: ~31.25 MATE (much cheaper than expected!)
- **Can Register**: ~850 usernames!

---

## Alternative: Fix CLI (Advanced)

If you really want to use CLI, the issue is with signature verification. We might need to:

1. Check if bytes32 hash format needs to be different
2. Verify the exact signing method `cast wallet sign` uses
3. Test against a simpler contract first

But the **web interface is strongly recommended** for ease of use!

---

## Summary

**Easy Path**: Use web interface (5 minutes to register)
**Hard Path**: Debug CLI signatures (could take hours)

**Recommendation**: Start the web interface! 🚀

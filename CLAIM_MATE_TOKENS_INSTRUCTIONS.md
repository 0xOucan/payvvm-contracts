# How to Claim MATE Tokens

## Discovery

I found that the EVVM contract has a **public function `recalculateReward()`** that gives MATE tokens to anyone who calls it!

### How It Works

Looking at the contract code (Evvm.sol:1055-1066):
```solidity
function recalculateReward() public {
    if (evvmMetadata.totalSupply > evvmMetadata.eraTokens) {
        evvmMetadata.eraTokens += ((evvmMetadata.totalSupply - evvmMetadata.eraTokens) / 2);
        balances[msg.sender][evvmMetadata.principalTokenAddress] += 
            evvmMetadata.reward * getRandom(1, 5083);
        evvmMetadata.reward = evvmMetadata.reward / 2;
    } else {
        revert();
    }
}
```

**What you get:** `reward × random(1, 5083)` = `5 MATE × random(1-5083)` = **5 to 25,415 MATE tokens**!

### Current Status

- Total Supply: 2,033,333,333 MATE
- Era Tokens: 1,016,666,666.5 MATE
- Reward: 5 MATE
- **Condition Met:** totalSupply (2B) > eraTokens (1B) ✅

You can call this function RIGHT NOW and get thousands of MATE tokens - way more than the 500 MATE needed for username registration!

## Quick Command

Run this command in your terminal:

```bash
cd /home/oucan/PayVVM/PAYVVM
source .env
cast send 0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e \
    "recalculateReward()" \
    --account monad-deployer \
    --rpc-url $RPC_URL_ETH_SEPOLIA
```

You'll be prompted for your monad-deployer keystore password.

## Check Your Balance After

```bash
source .env
EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
PRINCIPAL_TOKEN="0x0000000000000000000000000000000000000001"
YOUR_ADDRESS=$(cast wallet address --account monad-deployer)

cast call $EVVM \
    "getBalance(address,address)(uint256)" \
    $YOUR_ADDRESS \
    $PRINCIPAL_TOKEN \
    --rpc-url $RPC_URL_ETH_SEPOLIA
```

## Or Use the Script

I created `./claim-mate-tokens.sh` that does this for you:

```bash
./claim-mate-tokens.sh monad-deployer
```

## What Happens

1. You call `recalculateReward()`
2. Contract generates random number between 1-5083
3. You receive: 5 MATE × random number
4. Minimum: 5 MATE
5. Maximum: 25,415 MATE!
6. **You now have enough MATE to register usernames** (need 500 MATE each)

## Side Effects

- This function also:
  - Increases `eraTokens` by half of the difference
  - Halves the `reward` amount for future calls
  - This is the "era transition" mechanism

## Next Step

After claiming MATE tokens, we'll build the proper EIP-191 signature generation for username registration!

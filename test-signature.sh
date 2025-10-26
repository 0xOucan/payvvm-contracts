#!/bin/bash
source .env

EVVM="0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e"
EVVM_ID=0
HASH="0xc9758e584bad0b06282239f3ea987ac0ab40dd66714bf46087d4ce35f894faad"
NONCE=176102314683936
SIGNER="0x9c77c6fafc1eb0821F1De12972Ef0199C97C6e45"

MESSAGE="$EVVM_ID,preRegistrationUsername,$HASH,$NONCE"

echo "Message to sign: $MESSAGE"
echo ""
echo "Message length: ${#MESSAGE}"
echo ""

# Calculate what Solidity would hash
MESSAGE_BYTES=$(printf "%s" "$MESSAGE" | xxd -p | tr -d '\n')
MESSAGE_LEN=${#MESSAGE}

echo "Ethereum Signed Message format:"
echo "\\x19Ethereum Signed Message:\\n${MESSAGE_LEN}${MESSAGE}"
echo ""

# Sign it
SIGNATURE=$(cast wallet sign --account monad-deployer "$MESSAGE")
echo "Signature: $SIGNATURE"
echo ""

# Recover signer
RECOVERED=$(cast wallet verify --address $SIGNER "$MESSAGE" "$SIGNATURE" && echo "✅ VERIFIED" || echo "❌ FAILED")
echo "Verification: $RECOVERED"

#!/usr/bin/env node

const { createPublicClient, http, keccak256, toHex, stringToHex, recoverMessageAddress } = require('viem');
const { privateKeyToAccount } = require('viem/accounts');
const { sepolia } = require('viem/chains');
const readline = require('readline');

require('dotenv').config();

async function main() {
    console.log('=== Local Signature Recovery Test ===\n');

    // Ask for private key
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    const privateKey = await new Promise((resolve) => {
        rl.question('Enter private key (will not be stored): ', (answer) => {
            rl.close();
            resolve(answer.trim());
        });
    });

    // Create account
    const account = privateKeyToAccount(privateKey);
    console.log(`Account address: ${account.address}\n`);

    // Test values (match diagnose-signature.sh)
    const username = 'test';
    const secret = '1234567890';
    const combined = username + secret;

    // Generate hash
    const preRegHash = keccak256(stringToHex(combined));
    console.log(`Hash: ${preRegHash}`);

    // Generate nonce
    const nsNonce = BigInt(Date.now().toString().slice(-15));
    console.log(`Nonce: ${nsNonce}`);

    // Create message (EVVM ID is 0)
    const evvmId = 0;
    const message = `${evvmId},preRegistrationUsername,${preRegHash},${nsNonce}`;
    console.log(`Message: ${message}`);
    console.log(`Message length: ${message.length}\n`);

    // Sign the message
    console.log('Signing message...');
    const signature = await account.signMessage({ message });
    console.log(`Signature: ${signature}\n`);

    // Recover the address from the signature
    console.log('Recovering address from signature...');
    const recoveredAddress = await recoverMessageAddress({
        message,
        signature
    });

    console.log(`\nRecovered address: ${recoveredAddress}`);
    console.log(`Expected address:  ${account.address}`);

    if (recoveredAddress.toLowerCase() === account.address.toLowerCase()) {
        console.log('\n✅ SUCCESS! Signature is valid and recovers to correct address');
        console.log('This means our signing is correct.');
        console.log('The issue must be with the contract or how we\'re calling it.');
    } else {
        console.log('\n❌ FAILURE! Signature does not recover to correct address');
        console.log('This would explain why the contract is rejecting our signatures.');
    }
}

main().catch((error) => {
    console.error('Error:', error.message);
    process.exit(1);
});

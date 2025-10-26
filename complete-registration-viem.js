#!/usr/bin/env node

const { createPublicClient, createWalletClient, http } = require('viem');
const { privateKeyToAccount } = require('viem/accounts');
const { sepolia } = require('viem/chains');
const fs = require('fs');
const readline = require('readline');

// Contract addresses
const EVVM_ADDRESS = '0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e';
const NAME_SERVICE_ADDRESS = '0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55';

// Get parameters
let username = process.argv[2];
let secret = process.argv[3];

// Try to load from file if not provided
if (!username && fs.existsSync('.registration-pending')) {
    console.log('Loading registration info from .registration-pending...\n');
    const content = fs.readFileSync('.registration-pending', 'utf8');
    const data = {};
    content.split('\n').forEach(line => {
        const [key, value] = line.split('=');
        if (key && value) data[key.toLowerCase()] = value;
    });
    username = data.username;
    secret = data.secret;
    console.log(`Found: ${username} (secret: ${secret})\n`);
}

if (!username || !secret) {
    console.log('Usage: node complete-registration-viem.js <username> <secret>');
    console.log('Or run without arguments if you have .registration-pending file');
    process.exit(1);
}

// Load environment
require('dotenv').config();
const RPC_URL = process.env.RPC_URL_ETH_SEPOLIA;

async function main() {
    console.log('=========================================');
    console.log('Complete .payvvm Name Registration (Viem)');
    console.log('=========================================');
    console.log(`Username: ${username}`);
    console.log(`Secret: ${secret}`);
    console.log('=========================================\n');

    // Ask for private key
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    const privateKey = await new Promise((resolve) => {
        rl.question('Enter your private key: ', (answer) => {
            rl.close();
            resolve(answer.trim());
        });
    });

    // Create account from private key
    const account = privateKeyToAccount(privateKey);
    console.log(`Your address: ${account.address}\n`);

    // Create clients
    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(RPC_URL)
    });

    const walletClient = createWalletClient({
        account,
        chain: sepolia,
        transport: http(RPC_URL)
    });

    // Get EVVM ID
    const evvmId = await publicClient.readContract({
        address: EVVM_ADDRESS,
        abi: [{
            name: 'getEvvmID',
            type: 'function',
            stateMutability: 'view',
            inputs: [],
            outputs: [{ type: 'uint256' }]
        }],
        functionName: 'getEvvmID'
    });

    console.log(`EVVM ID: ${evvmId}\n`);

    // Generate new nonces
    const nsNonce = BigInt(Date.now() * 1000 + Math.floor(Math.random() * 1000));

    const evvmNonce = await publicClient.readContract({
        address: EVVM_ADDRESS,
        abi: [{
            name: 'getNextCurrentSyncNonce',
            type: 'function',
            stateMutability: 'view',
            inputs: [{ type: 'address' }],
            outputs: [{ type: 'uint256' }]
        }],
        functionName: 'getNextCurrentSyncNonce',
        args: [account.address]
    });

    console.log(`NameService nonce: ${nsNonce}`);
    console.log(`EVVM nonce: ${evvmNonce}\n`);

    // Create NameService signature for registration
    const nsMessage = `${evvmId},registrationUsername,${username},${secret},${nsNonce}`;
    console.log('=========================================');
    console.log('Generating Signatures');
    console.log('=========================================\n');
    console.log('Signing NameService message...');
    console.log(`Message: ${nsMessage}\n`);

    const nsSignature = await walletClient.signMessage({
        account,
        message: nsMessage
    });

    console.log(`NameService signature: ${nsSignature}\n`);

    console.log('=========================================');
    console.log('Completing Registration');
    console.log('=========================================\n');

    try {
        const txHash = await walletClient.writeContract({
            account,
            address: NAME_SERVICE_ADDRESS,
            abi: [{
                name: 'registrationUsername',
                type: 'function',
                stateMutability: 'nonpayable',
                inputs: [
                    { name: 'user', type: 'address' },
                    { name: 'username', type: 'string' },
                    { name: 'clowNumber', type: 'uint256' },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'signature', type: 'bytes' },
                    { name: 'priorityFee_EVVM', type: 'uint256' },
                    { name: 'nonce_EVVM', type: 'uint256' },
                    { name: 'priorityFlag_EVVM', type: 'bool' },
                    { name: 'signature_EVVM', type: 'bytes' }
                ],
                outputs: []
            }],
            functionName: 'registrationUsername',
            args: [
                account.address,
                username,
                BigInt(secret),
                nsNonce,
                nsSignature,
                0n, // priorityFee_EVVM
                evvmNonce,
                false, // priorityFlag_EVVM
                '0x' // empty signature
            ]
        });

        console.log(`Transaction hash: ${txHash}`);
        console.log('Waiting for confirmation...\n');

        const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

        console.log('✅ Registration Complete!\n');
        console.log(`Block: ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed}\n`);

        console.log('=========================================');
        console.log('🎉 Success!');
        console.log('=========================================');
        console.log(`\nYour username: $${username}.payvvm`);
        console.log(`Points to: ${account.address}\n`);

        // Clean up
        if (fs.existsSync('.registration-pending')) {
            fs.unlinkSync('.registration-pending');
        }

    } catch (error) {
        console.error('❌ Transaction failed:');
        console.error(error.message);

        if (error.message.includes('PreRegistrationNotValid')) {
            console.error('\n⏰ You may need to wait 30 minutes after pre-registration');
        }

        if (error.details) {
            console.error('\nDetails:', error.details);
        }

        if (error.data?.errorName) {
            console.error(`\nContract error: ${error.data.errorName}`);
        }

        process.exit(1);
    }
}

main().catch((error) => {
    console.error('Error:', error.message);
    process.exit(1);
});

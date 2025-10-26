#!/usr/bin/env node

const { createPublicClient, createWalletClient, http, keccak256, toHex, stringToHex } = require('viem');
const { privateKeyToAccount } = require('viem/accounts');
const { sepolia } = require('viem/chains');
const fs = require('fs');
const readline = require('readline');

// Contract addresses
const EVVM_ADDRESS = '0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e';
const NAME_SERVICE_ADDRESS = '0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55';
const PRINCIPAL_TOKEN = '0x0000000000000000000000000000000000000001';

// Get username from command line
const username = process.argv[2];
if (!username) {
    console.log('Usage: node register-name-viem.js <username>');
    console.log('Example: node register-name-viem.js test');
    process.exit(1);
}

// Load environment
require('dotenv').config();
const RPC_URL = process.env.RPC_URL_ETH_SEPOLIA;

if (!RPC_URL) {
    console.error('Error: RPC_URL_ETH_SEPOLIA not found in .env');
    process.exit(1);
}

async function main() {
    console.log('=========================================');
    console.log('Register .payvvm Name with Viem');
    console.log('=========================================');
    console.log(`Username: ${username}`);
    console.log(`Will be: $${username}.payvvm`);
    console.log('=========================================\n');

    // Ask for private key
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    const privateKey = await new Promise((resolve) => {
        rl.question('Enter your private key (will not be stored): ', (answer) => {
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

    // Generate secret
    const secret = Date.now().toString().slice(-10);
    console.log(`Generated secret: ${secret}`);

    // Calculate hash: keccak256(username + secret)
    // Must match Solidity's abi.encodePacked(string, string)
    const combined = username + secret;
    const preRegHash = keccak256(stringToHex(combined));
    console.log(`Pre-registration hash: ${preRegHash}\n`);

    // Generate nonces
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

    // Create NameService signature
    const nsMessage = `${evvmId},preRegistrationUsername,${preRegHash},${nsNonce}`;
    console.log('=========================================');
    console.log('Generating Signatures');
    console.log('=========================================\n');
    console.log('Signing NameService message...');
    console.log(`Message: ${nsMessage}\n`);

    // Viem's signMessage - uses EIP-191 by default
    const nsSignature = await walletClient.signMessage({
        account,
        message: nsMessage
    });

    console.log(`NameService signature: ${nsSignature}\n`);

    console.log('=========================================');
    console.log('Submitting Pre-Registration');
    console.log('=========================================\n');

    try {
        // Send transaction
        const txHash = await walletClient.writeContract({
            account,
            address: NAME_SERVICE_ADDRESS,
            abi: [{
                name: 'preRegistrationUsername',
                type: 'function',
                stateMutability: 'nonpayable',
                inputs: [
                    { name: 'user', type: 'address' },
                    { name: 'hashPreRegisteredUsername', type: 'bytes32' },
                    { name: 'nonce', type: 'uint256' },
                    { name: 'signature', type: 'bytes' },
                    { name: 'priorityFee_EVVM', type: 'uint256' },
                    { name: 'nonce_EVVM', type: 'uint256' },
                    { name: 'priorityFlag_EVVM', type: 'bool' },
                    { name: 'signature_EVVM', type: 'bytes' }
                ],
                outputs: []
            }],
            functionName: 'preRegistrationUsername',
            args: [
                account.address,
                preRegHash,
                nsNonce,
                nsSignature,
                0n, // priorityFee_EVVM
                evvmNonce,
                false, // priorityFlag_EVVM
                '0x' // empty signature since priorityFee = 0
            ]
        });

        console.log(`Transaction hash: ${txHash}`);
        console.log('Waiting for confirmation...\n');

        const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

        console.log('✅ Pre-Registration Complete!\n');
        console.log(`Block: ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed}\n`);

        // Save registration info
        const regInfo = {
            username,
            secret,
            walletAddress: account.address,
            timestamp: Date.now(),
            nsNonce: nsNonce.toString(),
            hash: preRegHash
        };

        fs.writeFileSync('.registration-pending',
            Object.entries(regInfo).map(([k, v]) => `${k.toUpperCase()}=${v}`).join('\n')
        );

        console.log('=========================================');
        console.log('⏰ Wait 30 minutes before completing registration');
        console.log('=========================================');
        console.log(`\nSave this information:`);
        console.log(`  Username: ${username}`);
        console.log(`  Secret: ${secret}\n`);
        console.log('After 30 minutes, run:');
        console.log(`  node complete-registration-viem.js ${username} ${secret}\n`);

    } catch (error) {
        console.error('❌ Transaction failed:');
        console.error(error.message);

        if (error.details) {
            console.error('\nDetails:', error.details);
        }

        // Check if it's a contract revert
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

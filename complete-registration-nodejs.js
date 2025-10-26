#!/usr/bin/env node

const ethers = require('ethers');
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
    console.log('Usage: node complete-registration-nodejs.js <username> <secret>');
    console.log('Or run without arguments if you have .registration-pending file');
    process.exit(1);
}

// Load environment
require('dotenv').config();
const RPC_URL = process.env.RPC_URL_ETH_SEPOLIA;

async function main() {
    console.log('=========================================');
    console.log('Complete .payvvm Name Registration');
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

    // Setup provider and wallet
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(privateKey, provider);

    console.log(`Your address: ${wallet.address}\n`);

    // Get EVVM ID
    const evvmAbi = ['function getEvvmID() view returns (uint256)'];
    const evvmContract = new ethers.Contract(EVVM_ADDRESS, evvmAbi, provider);
    const evvmId = await evvmContract.getEvvmID();
    console.log(`EVVM ID: ${evvmId}\n`);

    // Generate new nonces
    const nsNonce = Date.now() * 1000 + Math.floor(Math.random() * 1000);
    const evvmNonceAbi = ['function getNextCurrentSyncNonce(address) view returns (uint256)'];
    const evvmNonceContract = new ethers.Contract(EVVM_ADDRESS, evvmNonceAbi, provider);
    const evvmNonce = await evvmNonceContract.getNextCurrentSyncNonce(wallet.address);

    console.log(`NameService nonce: ${nsNonce}`);
    console.log(`EVVM nonce: ${evvmNonce}\n`);

    // Create NameService signature for registration
    const nsMessage = `${evvmId},registrationUsername,${username},${secret},${nsNonce}`;
    console.log('Signing NameService message...');
    console.log(`Message: ${nsMessage}`);

    const nsSignature = await wallet.signMessage(nsMessage);
    console.log(`Signature: ${nsSignature}\n`);

    // Prepare transaction
    const nameServiceAbi = [
        'function registrationUsername(address user, string username, uint256 clowNumber, uint256 nonce, bytes signature, uint256 priorityFee_EVVM, uint256 nonce_EVVM, bool priorityFlag_EVVM, bytes signature_EVVM)'
    ];
    const nameServiceContract = new ethers.Contract(NAME_SERVICE_ADDRESS, nameServiceAbi, wallet);

    console.log('=========================================');
    console.log('Completing Registration');
    console.log('=========================================\n');

    try {
        const tx = await nameServiceContract.registrationUsername(
            wallet.address,
            username,
            secret,
            nsNonce,
            nsSignature,
            0, // priorityFee_EVVM
            evvmNonce,
            false, // priorityFlag_EVVM
            '0x' // empty signature
        );

        console.log(`Transaction hash: ${tx.hash}`);
        console.log('Waiting for confirmation...\n');

        const receipt = await tx.wait();
        console.log('✅ Registration Complete!\n');
        console.log(`Block: ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed}\n`);

        console.log('=========================================');
        console.log('🎉 Success!');
        console.log('=========================================');
        console.log(`\nYour username: $${username}.payvvm`);
        console.log(`Points to: ${wallet.address}\n`);

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

        if (error.data) {
            console.error('\nError data:', error.data);
        }

        process.exit(1);
    }
}

main().catch((error) => {
    console.error('Error:', error.message);
    process.exit(1);
});

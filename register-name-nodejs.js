#!/usr/bin/env node

const ethers = require('ethers');
const fs = require('fs');
const readline = require('readline');

// Contract addresses
const EVVM_ADDRESS = '0x9486f6C9d28ECdd95aba5bfa6188Bbc104d89C3e';
const NAME_SERVICE_ADDRESS = '0xa4ba4e9270bDE8FbBF4328925959287a72BA0a55';
const PRINCIPAL_TOKEN = '0x0000000000000000000000000000000000000001';

// Get username from command line
const username = process.argv[2];
if (!username) {
    console.log('Usage: node register-name-nodejs.js <username>');
    console.log('Example: node register-name-nodejs.js test');
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
    console.log('Register .payvvm Name with Node.js');
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

    // Setup provider and wallet
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const wallet = new ethers.Wallet(privateKey, provider);

    console.log(`Your address: ${wallet.address}\n`);

    // Get EVVM ID
    const evvmAbi = ['function getEvvmID() view returns (uint256)'];
    const evvmContract = new ethers.Contract(EVVM_ADDRESS, evvmAbi, provider);
    const evvmId = await evvmContract.getEvvmID();
    console.log(`EVVM ID: ${evvmId}\n`);

    // Generate secret
    const secret = Date.now().toString().slice(-10);
    console.log(`Generated secret: ${secret}`);

    // Calculate hash: keccak256(username + secret)
    const combined = username + secret;
    const hash = ethers.keccak256(ethers.toUtf8Bytes(combined));
    console.log(`Pre-registration hash: ${hash}\n`);

    // Generate nonces
    const nsNonce = Date.now() * 1000 + Math.floor(Math.random() * 1000);
    const evvmNonceAbi = ['function getNextCurrentSyncNonce(address) view returns (uint256)'];
    const evvmNonceContract = new ethers.Contract(EVVM_ADDRESS, evvmNonceAbi, provider);
    const evvmNonce = await evvmNonceContract.getNextCurrentSyncNonce(wallet.address);

    console.log(`NameService nonce: ${nsNonce}`);
    console.log(`EVVM nonce: ${evvmNonce}\n`);

    // Create NameService signature
    const nsMessage = `${evvmId},preRegistrationUsername,${hash},${nsNonce}`;
    console.log('Signing NameService message...');
    console.log(`Message: ${nsMessage}`);

    const nsSignature = await wallet.signMessage(nsMessage);
    console.log(`Signature: ${nsSignature}\n`);

    // Since priorityFee = 0, we don't need valid EVVM signature
    const dummySignature = '0x' + '00'.repeat(65);

    // Prepare transaction
    const nameServiceAbi = [
        'function preRegistrationUsername(address user, bytes32 hashPreRegisteredUsername, uint256 nonce, bytes signature, uint256 priorityFee_EVVM, uint256 nonce_EVVM, bool priorityFlag_EVVM, bytes signature_EVVM)'
    ];
    const nameServiceContract = new ethers.Contract(NAME_SERVICE_ADDRESS, nameServiceAbi, wallet);

    console.log('=========================================');
    console.log('Submitting Pre-Registration');
    console.log('=========================================\n');

    try {
        const tx = await nameServiceContract.preRegistrationUsername(
            wallet.address,
            hash,
            nsNonce,
            nsSignature,
            0, // priorityFee_EVVM
            evvmNonce,
            false, // priorityFlag_EVVM
            '0x' // empty signature since priorityFee = 0
        );

        console.log(`Transaction hash: ${tx.hash}`);
        console.log('Waiting for confirmation...\n');

        const receipt = await tx.wait();
        console.log('✅ Pre-Registration Complete!\n');
        console.log(`Block: ${receipt.blockNumber}`);
        console.log(`Gas used: ${receipt.gasUsed}\n`);

        // Save registration info
        const regInfo = {
            username,
            secret,
            walletAddress: wallet.address,
            timestamp: Date.now(),
            nsNonce,
            hash
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
        console.log(`  node complete-registration-nodejs.js ${username} ${secret}\n`);

    } catch (error) {
        console.error('❌ Transaction failed:');
        console.error(error.message);

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

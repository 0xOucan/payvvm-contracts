// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title PyusdFaucet - EVVM Service for Gasless PYUSD Distribution
 * @author PAYVVM Team
 * @notice Faucet service that distributes PYUSD tokens without requiring users to pay gas
 * @dev Uses EVVM's caPay() for gasless token distribution
 *
 * Key Features:
 * - Gasless PYUSD claims using EIP-191 signatures
 * - Configurable claim amount and cooldown period
 * - Async nonce system to prevent replay attacks
 * - Fisher-executed transactions (users don't pay gas)
 * - Owner-controlled funding and withdrawal
 *
 * Flow:
 * 1. Owner funds faucet with PYUSD (deposits to EVVM)
 * 2. User signs claim message off-chain (no gas)
 * 3. Fisher executes claim transaction on-chain
 * 4. Faucet uses caPay() to transfer PYUSD to user
 */

import {SignatureRecover} from "@EVVM/testnet/lib/SignatureRecover.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IEvvm {
    function caPay(address to, address token, uint256 amount) external;
    function getBalance(address user, address token) external view returns (uint256);
    function getEvvmID() external view returns (uint256);
}

contract PyusdFaucet {
    using Strings for uint256;
    using Strings for address;

    // ============ State Variables ============

    /// @notice EVVM contract address for payment operations
    IEvvm public immutable evvm;

    /// @notice PYUSD token address on Ethereum Sepolia
    address public immutable pyusdToken;

    /// @notice Owner address for admin operations
    address public owner;

    /// @notice Amount of PYUSD to distribute per claim (in token decimals)
    uint256 public claimAmount;

    /// @notice Cooldown period between claims (in seconds)
    uint256 public cooldownPeriod;

    /// @notice EVVM ID for signature verification
    uint256 public evvmId;

    // ============ Storage Mappings ============

    /// @notice Tracks last claim timestamp for each user
    mapping(address => uint256) public lastClaimTime;

    /// @notice Async nonce tracking to prevent replay attacks
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    // ============ Events ============

    event Claimed(address indexed user, uint256 amount, uint256 nonce);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event CooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
    event Funded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);

    // ============ Errors ============

    error OnlyOwner();
    error InvalidSignature();
    error NonceAlreadyUsed();
    error CooldownNotExpired(uint256 remainingTime);
    error InsufficientFaucetBalance();
    error InvalidAmount();
    error InvalidCooldown();

    // ============ Modifiers ============

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    // ============ Constructor ============

    /**
     * @notice Initialize the PYUSD faucet service
     * @param _evvm EVVM contract address
     * @param _pyusdToken PYUSD token address (Ethereum Sepolia)
     * @param _owner Faucet owner address
     * @param _claimAmount Amount of PYUSD per claim (in token decimals, e.g., 10 * 1e6 for 10 PYUSD)
     * @param _cooldownPeriod Cooldown between claims in seconds (e.g., 86400 for 24 hours)
     */
    constructor(
        address _evvm,
        address _pyusdToken,
        address _owner,
        uint256 _claimAmount,
        uint256 _cooldownPeriod
    ) {
        evvm = IEvvm(_evvm);
        pyusdToken = _pyusdToken;
        owner = _owner;
        claimAmount = _claimAmount;
        cooldownPeriod = _cooldownPeriod;
        evvmId = evvm.getEvvmID();
    }

    // ============ Core Functionality ============

    /**
     * @notice Claim PYUSD from faucet using signature-based gasless transaction
     * @dev Called by fishers who execute the signed message on behalf of users
     *
     * Signature Message Format:
     * {evvmID},claimPyusd,{claimer},{nonce}
     *
     * Example: "1000,claimPyusd,0x1234...,42"
     *
     * @param claimer Address claiming the PYUSD
     * @param nonce Unique nonce to prevent replay attacks (async nonce)
     * @param signature EIP-191 signature from claimer authorizing the claim
     */
    function claimPyusd(
        address claimer,
        uint256 nonce,
        bytes memory signature
    ) external {
        // 1. Verify nonce hasn't been used
        if (usedNonces[claimer][nonce]) {
            revert NonceAlreadyUsed();
        }

        // 2. Verify cooldown period has passed
        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime[claimer];
        if (lastClaimTime[claimer] != 0 && timeSinceLastClaim < cooldownPeriod) {
            revert CooldownNotExpired(cooldownPeriod - timeSinceLastClaim);
        }

        // 3. Check faucet has sufficient balance
        uint256 faucetBalance = evvm.getBalance(address(this), pyusdToken);
        if (faucetBalance < claimAmount) {
            revert InsufficientFaucetBalance();
        }

        // 4. Verify signature
        string memory inputs = string.concat(
            claimer.toHexString(),
            ",",
            nonce.toString()
        );

        bool isValid = SignatureRecover.signatureVerification(
            evvmId.toString(),
            "claimPyusd",
            inputs,
            signature,
            claimer
        );

        if (!isValid) {
            revert InvalidSignature();
        }

        // 5. Mark nonce as used
        usedNonces[claimer][nonce] = true;

        // 6. Update last claim time
        lastClaimTime[claimer] = block.timestamp;

        // 7. Transfer PYUSD using EVVM's caPay (gasless for user)
        evvm.caPay(claimer, pyusdToken, claimAmount);

        emit Claimed(claimer, claimAmount, nonce);
    }

    // ============ View Functions ============

    /**
     * @notice Check if an address can claim (cooldown expired)
     * @param user Address to check
     * @return eligible True if user can claim
     * @return remainingTime Seconds until next claim available (0 if can claim now)
     */
    function canClaim(address user) external view returns (bool eligible, uint256 remainingTime) {
        if (lastClaimTime[user] == 0) {
            return (true, 0);
        }

        uint256 timeSinceLastClaim = block.timestamp - lastClaimTime[user];
        if (timeSinceLastClaim >= cooldownPeriod) {
            return (true, 0);
        }

        return (false, cooldownPeriod - timeSinceLastClaim);
    }

    /**
     * @notice Get faucet's PYUSD balance in EVVM
     * @return Current PYUSD balance
     */
    function getFaucetBalance() external view returns (uint256) {
        return evvm.getBalance(address(this), pyusdToken);
    }

    /**
     * @notice Check if a nonce has been used by a user
     * @param user User address
     * @param nonce Nonce to check
     * @return True if nonce is used
     */
    function isNonceUsed(address user, uint256 nonce) external view returns (bool) {
        return usedNonces[user][nonce];
    }

    // ============ Admin Functions ============

    /**
     * @notice Update claim amount
     * @param newAmount New claim amount in token decimals
     */
    function setClaimAmount(uint256 newAmount) external onlyOwner {
        if (newAmount == 0) revert InvalidAmount();
        uint256 oldAmount = claimAmount;
        claimAmount = newAmount;
        emit ClaimAmountUpdated(oldAmount, newAmount);
    }

    /**
     * @notice Update cooldown period
     * @param newCooldown New cooldown in seconds
     */
    function setCooldownPeriod(uint256 newCooldown) external onlyOwner {
        if (newCooldown == 0) revert InvalidCooldown();
        uint256 oldCooldown = cooldownPeriod;
        cooldownPeriod = newCooldown;
        emit CooldownUpdated(oldCooldown, newCooldown);
    }

    /**
     * @notice Transfer ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAmount();
        owner = newOwner;
    }

    /**
     * @notice Withdraw PYUSD from faucet (emergency or refund)
     * @dev Uses caPay to transfer from this contract to recipient
     * @param recipient Address to receive withdrawn funds
     * @param amount Amount to withdraw
     */
    function withdraw(address recipient, uint256 amount) external onlyOwner {
        uint256 faucetBalance = evvm.getBalance(address(this), pyusdToken);
        if (faucetBalance < amount) revert InsufficientFaucetBalance();

        evvm.caPay(recipient, pyusdToken, amount);
        emit Withdrawn(recipient, amount);
    }
}

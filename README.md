# KipuBank - Smart Contract

## Description

KipuBank is a secure and efficient smart contract that implements a personal vault system on the Ethereum blockchain. It allows users to deposit and withdraw native tokens (ETH) with built-in security mechanisms including withdrawal limits and global deposit caps.

### Key Features

- Personal Vaults: Each user has their own isolated vault for storing ETH
- Withdrawal Threshold: Maximum withdrawal amount per transaction (configurable at deployment)
- Bank Cap: Global limit on total deposits across all users
- Security Patterns: Implements Check-Effects-Interactions pattern and uses custom errors
- Gas Optimization: Single read/write operations to state variables, with unchecked blocks where safe
- Complete Documentation: Full NatSpec documentation for all functions, events, and errors

### Technical Highlights

- Custom errors for gas-efficient error handling
- Events emitted for all state changes
- Modifiers for access control and validation
- Immutable variables for deployment-time configuration
- Secure ETH transfers using low-level call()
- Transaction counters for deposits and withdrawals

---

## Deployment Instructions

### Prerequisites

- Node.js (v16 or higher)
- MetaMask wallet with Sepolia ETH
- Remix IDE or Hardhat/Foundry

### Deployment via Remix

1. **Open Remix IDE**
   - Go to https://remix.ethereum.org

2. **Create the Contract File**
   - Create a new file: contracts/KipuBank.sol
   - Copy and paste the contract code

3. **Compile the Contract**
   - Go to "Solidity Compiler" tab
   - Select compiler version: 0.8.26
   - Click "Compile KipuBank.sol"

4. **Deploy to Sepolia**
   - Go to "Deploy & Run Transactions" tab
   - Environment: Select "Injected Provider - MetaMask"
   - Ensure MetaMask is connected to Sepolia network
   - Enter constructor parameters:
     - _WITHDRAWALTHRESHOLD: 1000000000000000000 (1 ETH in wei)
     - _BANKCAP: 10000000000000000000 (10 ETH in wei)
   - Click "Deploy" and confirm the transaction in MetaMask

5. **Verify the Contract**
   - Copy the deployed contract address
   - Go to Sepolia Etherscan
   - Navigate to the contract address
   - Click "Contract" then "Verify and Publish"
   - Follow the verification steps with:
     - Compiler version: v0.8.26+commit.8a97fa7a
     - Optimization: No
     - Constructor arguments (ABI-encoded)

### Deployment Parameters Explained

- Withdrawal Threshold: Maximum amount (in wei) that can be withdrawn in a single transaction. Example: 1000000000000000000 = 1 ETH
- Bank Cap: Maximum total amount (in wei) that can be deposited across all users. Example: 10000000000000000000 = 10 ETH

---

## How to Interact with the Contract

### Using Remix

After deployment, you can interact with the contract directly from Remix's "Deployed Contracts" section.

#### Read Functions (View/Pure - No gas cost)

- getBalance(address _user): Returns the vault balance of a specific user
- getDepositCount(): Returns total number of deposits made
- getWithdrawalCount(): Returns total number of withdrawals made
- getWithdrawalThreshold(): Returns the maximum withdrawal amount per transaction
- getBankCap(): Returns the global deposit limit
- getOwner(): Returns the contract owner address
- getTotalBalance(): Returns total ETH held in the contract

#### Write Functions (Require gas)

- deposit(): 
  - Deposits ETH into your personal vault
  - Must send ETH value with the transaction
  - Example: Set VALUE to 100000000000000000 (0.1 ETH) and click deposit
  
- withdraw(uint256 _amount):
  - Withdraws ETH from your vault
  - Amount must be less than or equal to withdrawal threshold
  - Amount must be less than or equal to your balance
  - Example: Enter 50000000000000000 (0.05 ETH) and click withdraw

### Using Etherscan

1. Go to the verified contract on Sepolia Etherscan (link below)
2. Navigate to "Contract" tab
3. Use "Read Contract" to view balances and parameters
4. Use "Write Contract" to:
   - Connect your wallet
   - Execute deposit and withdraw functions

### Using Web3 Libraries (ethers.js example)
```javascript
const { ethers } = require("ethers");

// Connect to Sepolia
const provider = new ethers.providers.JsonRpcProvider("YOUR_SEPOLIA_RPC_URL");
const wallet = new ethers.Wallet("YOUR_PRIVATE_KEY", provider);

// Contract setup
const contractAddress = "0x68fdfddb269245efaac097976dbc0eb6f5b6ce80";
const contractABI = [ /* ABI from Etherscan */ ];
const kipuBank = new ethers.Contract(contractAddress, contractABI, wallet);

// Deposit 0.1 ETH
const depositTx = await kipuBank.deposit({
  value: ethers.utils.parseEther("0.1")
});
await depositTx.wait();

// Check balance
const balance = await kipuBank.getBalance(wallet.address);
console.log("Balance:", ethers.utils.formatEther(balance), "ETH");

// Withdraw 0.05 ETH
const withdrawTx = await kipuBank.withdraw(
  ethers.utils.parseEther("0.05")
);
await withdrawTx.wait();
```

---

## Contract Information

### Deployed Contract

- Network: Sepolia Testnet
- Contract Address: 0x68fdfddb269245efaac097976dbc0eb6f5b6ce80
- Verified Contract: View on Sepolia Etherscan at https://sepolia.etherscan.io/address/0x68fdfddb269245efaac097976dbc0eb6f5b6ce80

### Contract Parameters

- Withdrawal Threshold: 1 ETH (1000000000000000000 wei)
- Bank Cap: 10 ETH (10000000000000000000 wei)
- Compiler Version: 0.8.26
- License: MIT

---

## Security Features

### Implemented Patterns

1. Check-Effects-Interactions: All state changes occur before external calls
2. Custom Errors: Gas-efficient error handling instead of string reverts
3. Access Control: onlyOwner modifier for administrative functions
4. Input Validation: withinThreshold modifier ensures withdrawal limits
5. Reentrancy Protection: CEI pattern prevents reentrancy attacks
6. Safe Math: Uses unchecked blocks only where overflow/underflow is impossible

### Gas Optimizations

- Single read and single write per state variable per function
- Immutable variables for constants set at deployment
- Unchecked arithmetic where safe (after validation)
- Custom errors instead of require strings

---

## Contract Architecture

### State Variables
```solidity
uint256 public immutable i_withdrawalThreshold;  // Max withdrawal per tx
uint256 public immutable i_bankCap;              // Global deposit limit
address private immutable i_owner;               // Contract owner
mapping(address => uint256) private s_balances;  // User vault balances
uint256 private s_depositCount;                  // Total deposits counter
uint256 private s_withdrawalCount;               // Total withdrawals counter
```

### Events
```solidity
event KipuBank__DepositSuccessful(address indexed user, uint256 amount);
event KipuBank__WithdrawalSuccessful(address indexed user, uint256 amount);
```

### Custom Errors
```solidity
error KipuBank__BankCapExceeded(uint256 currentTotal, uint256 attemptedDeposit, uint256 bankCap);
error KipuBank__InsufficientBalance(address user, uint256 available, uint256 requested);
error KipuBank__WithdrawalThresholdExceeded(uint256 requested, uint256 threshold);
error KipuBank__TransferFailed(address recipient);
error KipuBank__NotOwner(address caller, address owner);
error KipuBank__DepositAmountZero();
```

---

## Testing

### Manual Testing Checklist

- Deposit ETH successfully
- Withdraw ETH within threshold
- Attempt withdrawal exceeding threshold (should fail)
- Attempt withdrawal exceeding balance (should fail)
- Deposit exceeding bank cap (should fail)
- View functions return correct values
- Events are emitted correctly
- Access control functions properly

### Test Cases Executed

1. Deposited 0.1 ETH - Success
2. Withdrew 0.05 ETH - Success
3. Verified balance updates correctly
4. Confirmed deposit and withdrawal counters increment
5. Verified events emitted on Etherscan

---

## Development

### Project Structure
```
kipu-bank/
├── contracts/
│   └── KipuBank.sol
└── README.md
```

### Requirements

- Solidity ^0.8.26
- No external dependencies

---

## Author

- Author: Marcos del Río 
- GitHub: https://github.com/Marcos-script/
- Smart Contract: KipuBank.sol
- Ethereum Developer Pack - Module 2

---

## License

This project is licensed under the MIT License.

---

## Disclaimer

This contract is for educational purposes as part of the Ethereum Developer Pack course. It has not been audited and should not be used in production environments with real funds.

---

## Links

- Verified Contract: https://sepolia.etherscan.io/address/0x68fdfddb269245efaac097976dbc0eb6f5b6ce80
- Sepolia Faucet: https://sepoliafaucet.com/
- Remix IDE: https://remix.ethereum.org

---

## Support

For questions or issues regarding this contract, please open an issue in this repository.

---

Built with dedication for the Ethereum Developer Pack - Module 2

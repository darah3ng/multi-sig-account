# MultiSignAccount

> ✋ Warning: This project is for educational purposes only. Use at your own risk.

A multi-signature account abstraction smart contract that enables secure group-controlled transactions on Ethereum.

## Project Overview
### Purpose
Provides a secure way to manage shared funds requiring multiple confirmations before executing transactions.

### Key Features 
- Multiple owner management
- Configurable confirmation threshold
- Transaction submission and execution
- Owner-based access control
- Ether deposit handling
- Transaction confirmation tracking
- Withdrawal functionality

### Architecture
The contract implements:
- Transaction struct for tracking details and confirmation status
- Owner management with required confirmation thresholds
- Event emission for all major actions
- Modifier-based access control

## Development

### Prerequisites
- Foundry toolchain

### Foundry Setup
Foundry consists of:
- **Forge**: Ethereum testing framework
- **Cast**: CLI for contract interaction
- **Anvil**: Local Ethereum node
- **Chisel**: Solidity REPL

### Build & Test
```shell
# Build
forge build

# Test
forge test

# Format
forge fmt

# Gas Snapshots
forge snapshot
```

### Deploy & Interact

```bash
# Start local node
anvil

# Import existing wallet
cast wallet import <ACCOUNT_NAME> --interactive

# Deploy MultiSigAccount with owners and required confirmations
OWNERS='["<ADDRESS1>", "<ADDRESS2>"]' REQUIRED=2 forge script script/MultiSigAccount.s.sol --broadcast --rpc-url http://127.0.0.1:8545 --sender <WALLET_ADDRESS> --account <ACCOUNT_NAME>

# Submit transaction
cast send --private-key <PRIVATE_KEY> <CONTRACT_ADDRESS> "submitTransaction(address,uint256,bytes)" <TO_ADDRESS> <VALUE> <DATA> --rpc-url http://127.0.0.1:8545

# Confirm transaction
cast send --private-key <PRIVATE_KEY> <CONTRACT_ADDRESS> "confirmTransaction(uint256)" <TX_INDEX> --rpc-url http://127.0.0.1:8545

# Execute transaction
cast send --private-key <PRIVATE_KEY> <CONTRACT_ADDRESS> "executeTransaction(uint256)" <TX_INDEX> --rpc-url http://127.0.0.1:8545

# Get transaction count
cast call <CONTRACT_ADDRESS> "getTransactionCount()" --rpc-url http://127.0.0.1:8545
```
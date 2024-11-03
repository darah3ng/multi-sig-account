// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiSigAccount
 * @dev A basic multi-signature account abstraction
 */
contract MultiSigAccount {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    address[] public owners;
    uint256 public required;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(
        address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event WithdrawToOwner(uint256 amount);

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of owners");

        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            owners.push(_owners[i]);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawToOwner(uint256 _ownerIndex) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = owners[_ownerIndex].call{value: amount}("");

        emit WithdrawToOwner(amount);

        require(success, "Failed to send Ether");
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, confirmations: 0}));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex) public onlyOwner {
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed, "Transaction already executed");
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed by this owner");

        isConfirmed[_txIndex][msg.sender] = true;
        transaction.confirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex) public onlyOwner {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.confirmations >= required, "Not enough confirmations");
        require(!transaction.executed, "Transaction already executed");

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        Transaction storage txn = transactions[_txIndex];
        txn.executed = true;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex) public view returns (address, uint256, bytes memory, bool, uint256) {
        Transaction storage txn = transactions[_txIndex];
        return (
            txn.to,
            txn.value,
            txn.data, // This is of type `bytes`, so it needs `memory` in the return type
            txn.executed,
            txn.confirmations
        );
    }
}

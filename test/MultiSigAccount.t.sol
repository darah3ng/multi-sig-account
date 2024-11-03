// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import  {Test, console} from "forge-std/Test.sol";
import {MultiSigAccount} from "../src/MultiSigAccount.sol";

contract MultiSigAccountTest is Test {
  MultiSigAccount public multisig;
  address[] owners;
  uint256 required = 3;

  function setUp() public {
    // Create test addresses for 3 owners
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);

    // Setup owner addresses
    owners.push(owner1);
    owners.push(owner2);
    owners.push(owner3);

    // Deploy contract
    multisig = new MultiSigAccount(owners, required);

    // Fund the contract with 1 ETH for testing
    vm.deal(address(multisig), 1 ether);
  }

  function test_InitialSetup() public view {
    assertEq(multisig.getContractBalance(), 1 ether);
    assertEq(multisig.owners(0), owners[0]);
    assertEq(multisig.owners(1), owners[1]);
    assertEq(multisig.owners(2), owners[2]);
    assertEq(multisig.required(), required);
  }

  function test_SubmitTransaction() public {
    // Mock test data
    address targetAddress = address(0x4);
    uint256 value = 0.5 ether;
    bytes memory data = "";

    // Impersonate owner to submit transaction
    vm.prank(owners[0]);

    // Submit the transaction
    multisig.submitTransaction(targetAddress, value, data);

    // Get the transaction details
    (
      address to,
      uint256 txValue,
      bytes memory txData,
      bool executed,
      uint256 confirmations
    ) = multisig.getTransaction(0);

    // Verify the transaction details
    assertEq(to, targetAddress);
    assertEq(txValue, value);
    assertEq(txData, data);
    assertEq(executed, false);
    assertEq(confirmations, 0);

    // Verify transaction count increased
    assertEq(multisig.getTransactionCount(), 1);
  }

  function test_ConfirmTransaction() public {
    // Setup initial transaction
    address targetAddress = address(0x4);
    uint256 value = 0.5 ether;
    bytes memory data = "";
    
    // First owner submits transaction
    vm.prank(owners[0]);
    multisig.submitTransaction(targetAddress, value, data);
    
    // Second owner confirms transaction
    vm.prank(owners[1]);
    multisig.confirmTransaction(0);
    
    // Get transaction details
    (
        ,
        ,
        ,
        bool executed,
        uint256 confirmations
    ) = multisig.getTransaction(0);
    
    // Verify confirmation was recorded
    assertEq(confirmations, 1);
    assertEq(executed, false);
    assertTrue(multisig.isConfirmed(0, owners[1]));
  }

  function test_ExecuteTransaction() public {
    // Setup initial transaction
    address targetAddress = address(0x4);
    uint256 value = 0.5 ether;
    bytes memory data = "";
    
    // First owner submits transaction
    vm.prank(owners[0]);
    multisig.submitTransaction(targetAddress, value, data);

    // First owner confirms transaction
    vm.prank(owners[0]);
    multisig.confirmTransaction(0);
    
    // Second owner confirms transaction
    vm.prank(owners[1]);
    multisig.confirmTransaction(0);

    // Third owner confirms transaction
    vm.prank(owners[2]);
    multisig.confirmTransaction(0);

    // Second owner executes transaction
    vm.prank(owners[1]);
    multisig.executeTransaction(0);
    
    // Get transaction details
    (
        ,
        ,
        ,
        bool executed,
        uint256 confirmations
    ) = multisig.getTransaction(0);
    
    // Verify confirmation was recorded
    assertEq(confirmations, 3);
    assertEq(executed, true);
    assertTrue(multisig.isConfirmed(0, owners[0]));
    assertTrue(multisig.isConfirmed(0, owners[1]));
    assertTrue(multisig.isConfirmed(0, owners[2]));
  }

  function test_RevertSubmitTransactionNotOwner() public {
    // Mock test data
    address targetAddress = address(0x4);
    uint256 value = 0.5 ether;
    bytes memory data = "";

    address nonOwner = address(0x5);

    // Impersonate non-owner to submit transaction
    vm.prank(nonOwner);

    // Expect revert with specific message
    vm.expectRevert("Not owner");

    // Submit the transaction
    multisig.submitTransaction(targetAddress, value, data);
  }

    function test_RevertExecuteTransactionNotEnoughConfirmations() public {
    // Setup initial transaction
    address targetAddress = address(0x4);
    uint256 value = 0.5 ether;
    bytes memory data = "";
    
    // First owner submits transaction
    vm.prank(owners[0]);
    multisig.submitTransaction(targetAddress, value, data);

    // First owner confirms transaction
    vm.prank(owners[0]);
    multisig.confirmTransaction(0);
    
    // Second owner confirms transaction
    vm.prank(owners[1]);
    multisig.confirmTransaction(0);

    // Expect revert due to not enough confirmations
    vm.expectRevert("Not enough confirmations");

    // Second owner execute transaction
    vm.prank(owners[1]);
    multisig.executeTransaction(0);
  }

  function test_RevertConfirmTransactionAlreadyConfirmed() public {
      vm.prank(owners[0]);
      multisig.submitTransaction(address(0x123), 1 ether, "");
      
      vm.prank(owners[0]);
      multisig.confirmTransaction(0);
      
      vm.expectRevert("Transaction already confirmed by this owner");
      vm.prank(owners[0]);
      multisig.confirmTransaction(0);
  }

  function test_RevertConfirmTransactionAlreadyExecuted() public {
      address recipient = address(0x123);
      deal(address(multisig), 1 ether);
      
      vm.prank(owners[0]);
      multisig.submitTransaction(recipient, 1 ether, "");
      
      // Get required confirmations and execute
      vm.prank(owners[0]);
      multisig.confirmTransaction(0);
      vm.prank(owners[1]);
      multisig.confirmTransaction(0);
      vm.prank(owners[2]);
      multisig.confirmTransaction(0);
      vm.prank(owners[1]);
      multisig.executeTransaction(0);
      
      // Try to confirm after execution
      vm.expectRevert("Transaction already executed");
      vm.prank(owners[0]);
      multisig.confirmTransaction(0);
  }
}
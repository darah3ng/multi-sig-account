// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {MultiSigAccount} from "../src/MultiSigAccount.sol";

contract MultiSigAccountScript is Script {
  MultiSigAccount public multisig;

  function setUp() public {}

  function run() public {
    // Get owners from command line arguments
    string memory ownersRaw = vm.envString("OWNERS");
    string[] memory ownerStrings = vm.parseJsonStringArray(ownersRaw, "$");

    // Cast string addresses to address aray
    address[] memory owners = new address[](ownerStrings.length);
    for (uint256 i = 0; i < ownerStrings.length; i++) {
      owners[i] = vm.parseAddress(ownerStrings[i]);
    }

    // GET required confirmations from env
    uint256 required = vm.envUint("REQUIRED");

    // Deploy with 2 owners and requiring 2 confirmations
    vm.startBroadcast();
    multisig = new MultiSigAccount(owners, required);
    vm.stopBroadcast();
  }
}
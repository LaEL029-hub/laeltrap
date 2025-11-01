// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/InsurancePegTrap.sol";

contract DeployTrap is Script {
    function run() external {
        vm.startBroadcast();

        uint256 threshold = 900; // e.g., 10% deviation
        uint256 windowSeconds = 1800; // 30 minutes
        uint256 payoutAmount = 1 ether;

        InsurancePegTrap trap = new InsurancePegTrap(
            threshold,
            windowSeconds,
            payoutAmount
        );

        console.log("InsurancePegTrap deployed at:", address(trap));

        vm.stopBroadcast();
    }
}

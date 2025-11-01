// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PriceOracleMock} from "../src/PriceOracleMock.sol";
import {InsurancePolicyMock} from "../src/InsurancePolicyMock.sol";
import {ResponseContract} from "../src/ResponseContract.sol";

/**
 * @title DeployAll
 * @notice Deploys the PriceOracleMock, InsurancePolicyMock, and ResponseContract.
 * Then links the ResponseContract to the InsurancePolicyMock and funds the policy.
 */
contract DeployAll is Script {
    function run() public returns (address oracleAddr, address policyAddr, address responseAddr) {
        vm.startBroadcast();

        // 1. Deploy the Oracle
        PriceOracleMock oracle = new PriceOracleMock();
        oracleAddr = address(oracle);
        console.log("PriceOracleMock deployed at:", oracleAddr);

        // 2. Deploy the Policy (no value sent to constructor)
        InsurancePolicyMock policy = new InsurancePolicyMock(address(0)); // responder set later
        policyAddr = address(policy);
        console.log("InsurancePolicyMock deployed at:", policyAddr);

        // 3. Deploy the Response Contract
        ResponseContract response = new ResponseContract(policyAddr);
        responseAddr = address(response);
        console.log("ResponseContract deployed at:", responseAddr);

        // 4. Link response to policy
        policy.setAuthorizedResponder(responseAddr);
        console.log("Linked: ResponseContract authorized in InsurancePolicyMock.");

        // 5. Fund the Policy with 1 ETH (for payouts)
        payable(policyAddr).transfer(1 ether);
        console.log("Funded InsurancePolicyMock with 1 ETH.");

        vm.stopBroadcast();

        console.log("-----------------------------------------");
        console.log("Deployment Complete!");
        console.log("Oracle:", oracleAddr);
        console.log("Policy:", policyAddr);
        console.log("Response:", responseAddr);
        console.log("-----------------------------------------");

        return (oracleAddr, policyAddr, responseAddr);
    }
}

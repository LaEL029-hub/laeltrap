// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IInsurancePolicy {
    function payout(address payable recipient, uint256 amount) external;
}

contract ResponseContract {
    address public owner;
    address public immutable POLICY_ADDRESS;
    address public authorizedTrap; // trap or operator authorized to call

    event Responded(address indexed caller, address indexed destination, uint256 amount, string reason, uint256 ts);
    event AuthorizedTrapUpdated(address indexed oldTrap, address indexed newTrap);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    modifier onlyAuthorized() {
        require(msg.sender == authorizedTrap, "only authorized");
        _;
    }

    constructor(address _policyAddress) {
        owner = msg.sender;
        POLICY_ADDRESS = _policyAddress;
    }

    function setAuthorizedTrap(address _trap) external onlyOwner {
        emit AuthorizedTrapUpdated(authorizedTrap, _trap);
        authorizedTrap = _trap;
    }

    /// @notice Called by trap when condition met. Encodes payout parameters.
    /// Example: trap calls response(recipient, amount, "peg breach")
    function response(address payable recipient, uint256 amount, string calldata reason) external onlyAuthorized {
        // Execute payout on policy contract
        IInsurancePolicy(POLICY_ADDRESS).payout(recipient, amount);

        emit Responded(msg.sender, recipient, amount, reason, block.timestamp);
    }
}

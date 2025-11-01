// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Simple PoC insurance policy contract.
/// - Owner funds the contract with ETH (payable fallback)
/// - Payout function is callable by an authorized responder (set in constructor)
contract InsurancePolicyMock {
    address public owner;
    address public authorizedResponder;
    uint256 public totalPaid;

    event PayoutExecuted(address indexed to, uint256 amount, uint256 ts);
    event ResponderUpdated(address indexed oldResponder, address indexed newResponder);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    modifier onlyResponder() {
        require(msg.sender == authorizedResponder, "only responder");
        _;
    }

    constructor(address _authorizedResponder) {
        owner = msg.sender;
        authorizedResponder = _authorizedResponder;
    }

    receive() external payable {}
    fallback() external payable {}

    function setAuthorizedResponder(address r) external onlyOwner {
        emit ResponderUpdated(authorizedResponder, r);
        authorizedResponder = r;
    }

    /// @notice PoC payout — sends ETH from contract to recipient.
    function payout(address payable recipient, uint256 amount) external onlyResponder {
        require(address(this).balance >= amount, "insufficient funds");
        totalPaid += amount;
        (bool s,) = recipient.call{value: amount}("");
        require(s, "transfer failed");
        emit PayoutExecuted(recipient, amount, block.timestamp);
    }

    /// @notice helper: contract balance
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

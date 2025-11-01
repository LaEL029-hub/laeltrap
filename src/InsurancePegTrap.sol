// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IPriceOracle {
    function timeBelow(uint256 threshold, uint256 windowSeconds) external view returns (uint256 secondsBelow, uint256 currentTs);
}

contract InsurancePegTrap is ITrap {
    // Hardcoded contract references
    address public constant ORACLE_ADDRESS = 0x238d7f78E193bb081e8eff4F0F4c0E72c6094f2c;
    address public constant RESPONSE_CONTRACT_ADDRESS = 0x278fddf3540AD0bA675fCbC705435B8B5cF2f28A;

    // Hardcoded parameters
    uint256 public constant THRESHOLD = 900; // i.e. $0.90
    uint256 public constant WINDOW_SECONDS = 1800; // 30 min
    uint256 public constant PAYOUT_AMOUNT = 1 ether;
    address public constant PAYOUT_RECIPIENT = 0x8F1364587b01aA37fe8B7B1cCC79858DA1730814;

    constructor() {}

    function collect() external view override returns (bytes memory) {
        (bool ok, bytes memory ret) = ORACLE_ADDRESS.staticcall(
            abi.encodeWithSignature("timeBelow(uint256,uint256)", THRESHOLD, WINDOW_SECONDS)
        );

        if (!ok || ret.length == 0) {
            return abi.encode(uint256(0), uint256(block.timestamp), PAYOUT_AMOUNT, PAYOUT_RECIPIENT);
        }

        (uint256 secondsBelow, uint256 currentTs) = abi.decode(ret, (uint256, uint256));
        return abi.encode(secondsBelow, currentTs, PAYOUT_AMOUNT, PAYOUT_RECIPIENT);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length == 0 || data[0].length == 0) return (false, bytes(""));

        (uint256 secondsBelow, , uint256 payAmt, address recipient) =
            abi.decode(data[0], (uint256, uint256, uint256, address));

        if (secondsBelow > 0 && payAmt > 0) {
            string memory reason = "Peg breach: parametric payout";
            return (true, abi.encode(recipient, payAmt, reason));
        }

        return (false, bytes(""));
    }

    function getResponseContract() external pure returns (address) {
        return RESPONSE_CONTRACT_ADDRESS;
    }

    function getResponseFunction() external pure returns (string memory) {
        return "response(address,uint256,string)";
    }

    function getResponseArguments(uint256 amount, address recipient) external pure returns (bytes memory) {
        return abi.encode(recipient, amount, "Peg breach: parametric payout");
    }
}

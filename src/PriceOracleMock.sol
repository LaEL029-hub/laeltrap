// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Very small PoC price oracle.
/// - push prices with updatePrice(uint256 price) (price as integer, e.g. 900 = $0.90 if using 1e3 scaling)
/// - timeBelow(threshold, windowSeconds) returns (secondsBelow, currentTs)
contract PriceOracleMock {
    struct Update {
        uint256 price;
        uint256 ts;
    }

    Update[] public updates;
    address public owner;

    event PriceUpdated(uint256 price, uint256 ts);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    /// @notice push a new price (for PoC)
    function updatePrice(uint256 price) external {
        updates.push(Update({price: price, ts: block.timestamp}));
        emit PriceUpdated(price, block.timestamp);
    }

    /// @notice Return latest price
    function latestPrice() external view returns (uint256) {
        if (updates.length == 0) return 0;
        return updates[updates.length - 1].price;
    }

    /// @notice For PoC: compute how many seconds in the last `windowSeconds` the price was < threshold./// Scans updates backwards until window start. Gas-costly — OK for PoC mocks.
    /// @param threshold threshold price (same units as updatePrice)
    /// @param windowSeconds seconds to look back (sliding window)
    /// @return secondsBelow how many seconds in that window price < threshold
    /// @return currentTs block.timestamp (convenience)
    function timeBelow(uint256 threshold, uint256 windowSeconds) external view returns (uint256 secondsBelow, uint256 currentTs) {
        currentTs = block.timestamp;
        if (updates.length == 0) return (0, currentTs);
        uint256 windowStart = currentTs > windowSeconds ? (currentTs - windowSeconds) : 0;

        // Walk updates from most recent back to earliest within window.
        // Treat the period after the most recent update until now as constant at that price.
        uint256 len = updates.length;
        uint256 prevTs = currentTs;
        for (uint256 i = len; i > 0; ) {
            unchecked { --i; }
            Update memory u = updates[i];
            if (u.ts > prevTs) {
                // out-of-order update — skip (shouldn't happen)
                prevTs = u.ts;
                continue;
            }

            uint256 segmentEnd = prevTs;
            uint256 segmentStart = u.ts;
            if (segmentEnd <= windowStart) {
                // this whole segment is before the window -> stop scanning
                break;
            }
            if (segmentStart < windowStart) {
                segmentStart = windowStart;
            }

            if (u.price < threshold) {
                secondsBelow += (segmentEnd - segmentStart);
            }

            prevTs = u.ts;
            if (segmentStart == windowStart) break;
        }

        return (secondsBelow, currentTs);
    }
}

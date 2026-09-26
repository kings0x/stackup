// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/// @title StackConfig
/// @notice Immutable V1 risk constants for StackUp on Arc.
library StackConfig {
    uint256 internal constant BPS = 10_000;
    uint256 internal constant SPOT = 10_000; // 1.0x
    uint256 internal constant MAX_OPEN = 15_000; // 1.5x ceiling at open
    uint256 internal constant BORROW_APR_BPS = 1_000; // 10% simple
    uint256 internal constant MAINT_BPS = 3_000; // 30% equity/NAV
    uint256 internal constant ADVERSE_BPS = 9_900; // 1% haircut sizing (9900/10000 of ideal loan)
    uint256 internal constant YEAR = 365 days;

    function isPreset(uint256 lev) internal pure returns (bool) {
        return lev == 10_000 || lev == 11_000 || lev == 12_500 || lev == 14_000 || lev == 15_000;
    }

    /// @notice True when a stack must be unwound: positive debt and equity ratio below maintenance.
    function mustUnwind(uint256 nav, uint256 debt) internal pure returns (bool) {
        if (debt == 0) return false;
        if (debt >= nav) return true;
        uint256 equity = nav - debt;
        return equity * BPS < nav * MAINT_BPS;
    }
}

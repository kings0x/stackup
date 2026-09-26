// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStackVault} from "./interfaces/IStackModules.sol";

/// @title StackVault
/// @notice Protocol-owned USDC vault. Only the StackUp coordinator can draw.
contract StackVault {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDC;
    address public immutable stackUp;
    address public immutable treasury;

    error NotStackUp();
    error NotTreasury();
    error Zero();

    event Drawn(uint256 amount);
    event Funded(address indexed from, uint256 amount);
    event Withdrawn(uint256 amount);

    constructor(address usdc_, address stackUp_, address treasury_) {
        if (usdc_ == address(0) || stackUp_ == address(0) || treasury_ == address(0)) revert Zero();
        USDC = IERC20(usdc_);
        stackUp = stackUp_;
        treasury = treasury_;
    }

    function available() public view returns (uint256) {
        return USDC.balanceOf(address(this));
    }

    function draw(uint256 amount) external {
        if (msg.sender != stackUp) revert NotStackUp();
        USDC.safeTransfer(stackUp, amount);
        emit Drawn(amount);
    }

    function fund(uint256 amount) external {
        USDC.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(msg.sender, amount);
    }

    /// @notice Treasury can sweep idle USDC only (balance = idle by design; drawn capital lives in StackUp).
    function withdraw(uint256 amount) external {
        if (msg.sender != treasury) revert NotTreasury();
        USDC.safeTransfer(treasury, amount);
        emit Withdrawn(amount);
    }
}

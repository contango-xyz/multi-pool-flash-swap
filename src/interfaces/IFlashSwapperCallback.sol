// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Callback for IFlashSwapper
/// @notice Any contract that calls any function on IFlashSwapper must implement this interface
/// @dev The callback is called after the flash swap is executed, and must pay the owed amount to the pool.
/// @dev The callback implementation should check for slippage and revert if the slippage is unacceptable.
interface IFlashSwapperCallback {
    /// @notice Called to `msg.sender` after executing a flash swap via IFlashSwapper.
    /// @dev In the implementation you must pay `pool` tokens owed for the swap.
    /// The caller of this method must be checked to be the same instance of IFlashSwapper that was initially called.
    /// @param amountReceived The amount that was sent to the calling contract as proceeds of the flash swap.
    /// @param amountToRepay The amount the callback must send to `pool`.
    /// @param pool The address of the pool that's owed the `amountToRepay`.
    /// @param data Any data passed through by the caller via the IFlashSwapper data parameter.
    function flashSwapCallback(uint256 amountReceived, uint256 amountToRepay, address pool, bytes calldata data)
        external;
}

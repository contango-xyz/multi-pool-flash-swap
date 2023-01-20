// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router flash swapping functionality
/// @notice Functions for flash swapping tokens via Uniswap V3
interface IFlashSwapper is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        bytes data;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    function exactInputSingle(ExactInputSingleParams calldata params) external;

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        bytes data;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    function exactInput(ExactInputParams calldata params) external;

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        bytes data;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    function exactOutputSingle(ExactOutputSingleParams calldata params) external;

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        bytes data;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    function exactOutput(ExactOutputParams calldata params) external;
}

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

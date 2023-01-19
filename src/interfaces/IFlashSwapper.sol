// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IFlashSwapper is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        // address recipient;
        uint256 amountIn;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    function exactInputSingle(ExactInputSingleParams calldata params) external;

    struct ExactInputParams {
        bytes path;
        // address recipient;
        uint256 amountIn;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    function exactInput(ExactInputParams calldata params) external;

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        // address recipient;
        uint256 amountOut;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    function exactOutputSingle(ExactOutputSingleParams calldata params) external;

    struct ExactOutputParams {
        bytes path;
        // address recipient;
        uint256 amountOut;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    function exactOutput(ExactOutputParams calldata params) external;
}

interface IFlashSwapperCallback {
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, address pool, bytes calldata data)
        external;
}

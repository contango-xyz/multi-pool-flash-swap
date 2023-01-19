// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "./dependencies/Uniswap.sol";
import "./interfaces/IFlashSwapper.sol";

import "forge-std/console.sol";

contract FlashSwapper is IFlashSwapper {
    using Path for bytes;
    using SafeCast for uint256;
    using SafeTransferLib for ERC20;

    address internal constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public immutable weth;

    constructor(address _weth) {
        weth = _weth;
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
        address recipient;
        address firstPool;
        int256 amount0Delta;
        int256 amount1Delta;
        bytes data;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory cb = abi.decode(data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = cb.path.decodeFirstPool();
        CallbackValidation.verifyCallback(FACTORY, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountToPay, uint256 amountReceived) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta), uint256(-amount1Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta), uint256(-amount0Delta));

        if (isExactInput && cb.firstPool == address(0)) {
            console.log("firstPool", msg.sender);
            cb.firstPool = msg.sender;
            cb.amount0Delta = amount0Delta;
            cb.amount1Delta = amount1Delta;
        }

        if (isExactInput) {
            if (cb.firstPool != msg.sender) {
                ERC20(tokenIn).safeTransfer(msg.sender, amountToPay);
            }

            if (cb.path.hasMultiplePools()) {
                console.log("hasMultiplePools");

                cb.path = cb.path.skipToken();

                address recipient = cb.path.hasMultiplePools() ? address(this) : cb.recipient;

                _exactInput(amountReceived, recipient, cb);
            } else {
                console.log("noMultiplePools");

                IFlashSwapperCallback(cb.payer).uniswapV3SwapCallback(
                    cb.amount0Delta, cb.amount1Delta, cb.firstPool, cb.data
                );
            }
        } else {
            if (cb.path.hasMultiplePools()) {
                console.log("hasMultiplePools");

                cb.path = cb.path.skipToken();

                _exactOutput(amountToPay, msg.sender, cb);
            } else {
                console.log("noMultiplePools");

                IFlashSwapperCallback(cb.payer).uniswapV3SwapCallback(amount0Delta, amount1Delta, msg.sender, cb.data);
            }
        }
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external override {
        _exactInput(
            params.amountIn,
            params.recipient,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
                payer: msg.sender,
                firstPool: address(0),
                recipient: params.recipient,
                amount0Delta: 0,
                amount1Delta: 0,
                data: params.data
            })
        );
    }

    function exactInput(ExactInputParams calldata params) external override {
        require(params.path.hasMultiplePools(), "FlashSwapper: EXACT_INPUT_MULTIPLE_POOLS");

        _exactInput(
            params.amountIn,
            address(this),
            SwapCallbackData({
                path: params.path,
                payer: msg.sender,
                recipient: params.recipient,
                firstPool: address(0),
                amount0Delta: 0,
                amount1Delta: 0,
                data: params.data
            })
        );
    }

    function _exactInput(uint256 amountIn, address recipient, SwapCallbackData memory data) private {
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        _getPool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            amountIn.toInt256(),
            zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(data)
        );
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external override {
        // avoid an SLOAD by using the swap return data
        _exactOutput(
            params.amountOut,
            params.recipient,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenOut, params.fee, params.tokenIn),
                payer: msg.sender,
                recipient: params.recipient,
                firstPool: address(0),
                amount0Delta: 0,
                amount1Delta: 0,
                data: params.data
            })
        );

        // amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    function exactOutput(ExactOutputParams calldata params) external override {
        require(params.path.hasMultiplePools(), "FlashSwapper: EXACT_OUTPUT_MULTIPLE_POOLS");

        _exactOutput(
            params.amountOut,
            params.recipient,
            SwapCallbackData({
                path: params.path,
                payer: msg.sender,
                recipient: params.recipient,
                firstPool: address(0),
                amount0Delta: 0,
                amount1Delta: 0,
                data: params.data
            })
        );
    }

    function _exactOutput(uint256 amountOut, address recipient, SwapCallbackData memory data) private {
        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        _getPool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            -amountOut.toInt256(),
            zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(data)
        );
    }

    function _getPool(address tokenA, address tokenB, uint24 fee) private pure returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(FACTORY, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }
}

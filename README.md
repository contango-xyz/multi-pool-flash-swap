# multi-pool-flash-swap

Uniswap's SwapRouter re-implementation to allow for flash swaps involving multiple pools

## How to use

`FlashSwapper` works very similarly to Uniswap's `SwapRouter`, the main difference is that the calling contract should implement `IFlashSwapperCallback` to handle the flash swap.

It's very important to protect the callback method, so only calls from `FlashSwapper` are allowed.

Check the tests for a working example
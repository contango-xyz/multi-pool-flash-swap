// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/interfaces/IERC20.sol";
import "src/FlashSwapper.sol";

contract FlashSwapperTest is Test {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    bytes private expectedData = "data";

    address constant BOB = address(0xb0b);

    FlashSwapper internal flashSwapper;

    function setUp() public {
        vm.makePersistent(BOB);

        vm.createSelectFork("mainnet");

        vm.label(DAI, "DAI");
        vm.label(USDC, "USDC");
        vm.label(WETH, "WETH");
        vm.label(WBTC, "WBTC");

        flashSwapper = new FlashSwapper(WETH);
    }

    function testExactInputSingle() public {
        Caller caller = new Caller({_tokenIn:WETH, data: expectedData});

        IFlashSwapper.ExactInputSingleParams memory params = IFlashSwapper.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: USDC,
            fee: 500,
            recipient: BOB,
            amountIn: 1 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInputSingle(params);

        assertGt(IERC20(USDC).balanceOf(BOB), 1500e6);
    }

    function testExactInput_2Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, data: expectedData});

        IFlashSwapper.ExactInputParams memory params = IFlashSwapper.ExactInputParams({
            path: abi.encodePacked(WETH, uint24(500), USDC, uint24(100), DAI),
            recipient: BOB,
            amountIn: 1 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInput(params);

        assertGt(IERC20(DAI).balanceOf(BOB), 1500e18);
    }

    function testExactInput_3Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, data: expectedData});

        IFlashSwapper.ExactInputParams memory params = IFlashSwapper.ExactInputParams({
            path: abi.encodePacked(WETH, uint24(500), DAI, uint24(100), USDC, uint24(500), WBTC),
            recipient: BOB,
            amountIn: 15 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInput(params);

        assertGt(IERC20(WBTC).balanceOf(BOB), 1e8);
    }

    function testExactOutputSingle() public {
        Caller caller = new Caller({_tokenIn:WETH, data: expectedData});

        IFlashSwapper.ExactOutputSingleParams memory params = IFlashSwapper.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: USDC,
            fee: 500,
            recipient: BOB,
            amountOut: 1600e6,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutputSingle(params);

        // assertGt(IERC20(USDC).balanceOf(BOB), 1500e6);
        assertEq(IERC20(USDC).balanceOf(BOB), 1600e6);
    }

    function testExactOutput_2Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, data: expectedData});

        IFlashSwapper.ExactOutputParams memory params = IFlashSwapper.ExactOutputParams({
            path: abi.encodePacked(DAI, uint24(100), USDC, uint24(500), WETH),
            recipient: BOB,
            amountOut: 1600e18,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutput(params);

        assertEq(IERC20(DAI).balanceOf(BOB), 1600e18);
    }

    function testExactOutput_3Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, data: expectedData});

        IFlashSwapper.ExactOutputParams memory params = IFlashSwapper.ExactOutputParams({
            path: abi.encodePacked(WBTC, uint24(500), USDC, uint24(100), DAI, uint24(500), WETH),
            recipient: BOB,
            amountOut: 1e8,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutput(params);

        assertEq(IERC20(WBTC).balanceOf(BOB), 1e8);
    }
}

contract Caller is IFlashSwapperCallback, StdCheats, StdAssertions {
    address public immutable tokenIn;
    bytes public expectedData;

    constructor(address _tokenIn, bytes memory data) {
        tokenIn = _tokenIn;
        expectedData = data;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, address pool, bytes calldata data)
        external
        override
    {
        uint256 amountToPay =
            IERC20(tokenIn).balanceOf(pool) + (amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta));

        deal(tokenIn, pool, amountToPay);

        assertEq(data, expectedData);
    }
}

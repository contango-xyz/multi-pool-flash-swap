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

        vm.createSelectFork("mainnet", 16443750);

        vm.label(DAI, "DAI");
        vm.label(USDC, "USDC");
        vm.label(WETH, "WETH");
        vm.label(WBTC, "WBTC");

        flashSwapper = new FlashSwapper(WETH);
    }

    function testExactInputSingle() public {
        Caller caller = new Caller({_tokenIn:WETH});

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

        assertEqDecimal(IERC20(USDC).balanceOf(BOB), 1549.361628e6, 6);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amount0Delta(), -1549.361628e6, 6, "amount0Delta");
        assertEqDecimal(caller.amount1Delta(), 1 ether, 18, "amount1Delta");
    }

    function testExactInput_2Pools() public {
        Caller caller = new Caller({_tokenIn:WETH});

        IFlashSwapper.ExactInputParams memory params = IFlashSwapper.ExactInputParams({
            path: abi.encodePacked(WETH, uint24(500), USDC, uint24(100), DAI),
            recipient: BOB,
            amountIn: 1 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInput(params);

        assertEqDecimal(IERC20(DAI).balanceOf(BOB), 1549.166467184932744705e18, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amount0Delta(), -1549.166467184932744705e18, 18, "amount0Delta");
        assertEqDecimal(caller.amount1Delta(), 1 ether, 18, "amount1Delta");
    }

    function testExactInput_3Pools() public {
        Caller caller = new Caller({_tokenIn:WETH});

        IFlashSwapper.ExactInputParams memory params = IFlashSwapper.ExactInputParams({
            path: abi.encodePacked(WETH, uint24(500), DAI, uint24(100), USDC, uint24(500), WBTC),
            recipient: BOB,
            amountIn: 15 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInput(params);

        assertEqDecimal(IERC20(WBTC).balanceOf(BOB), 1.10409975e8, 8);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amount0Delta(), -1.10409975e8, 8, "amount0Delta");
        assertEqDecimal(caller.amount1Delta(), 15 ether, 18, "amount1Delta");
    }

    function testExactOutputSingle() public {
        Caller caller = new Caller({_tokenIn:WETH});

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

        assertEqDecimal(IERC20(USDC).balanceOf(BOB), 1600e6, 6);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amount0Delta(), -1600e6, 6, "amount0Delta");
        assertEqDecimal(caller.amount1Delta(), 1.032683399878123485 ether, 18, "amount1Delta");
    }

    function testExactOutput_2Pools() public {
        Caller caller = new Caller({_tokenIn:WETH});

        IFlashSwapper.ExactOutputParams memory params = IFlashSwapper.ExactOutputParams({
            path: abi.encodePacked(DAI, uint24(100), USDC, uint24(500), WETH),
            recipient: BOB,
            amountOut: 1600e18,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutput(params);

        assertEqDecimal(IERC20(DAI).balanceOf(BOB), 1600e18, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amount0Delta(), -1600e18, 18, "amount0Delta");
        assertEqDecimal(caller.amount1Delta(), 1.032813495483376696 ether, 18, "amount1Delta");
    }

    function testExactOutput_3Pools() public {
        Caller caller = new Caller({_tokenIn:WETH});

        IFlashSwapper.ExactOutputParams memory params = IFlashSwapper.ExactOutputParams({
            path: abi.encodePacked(WBTC, uint24(500), USDC, uint24(100), DAI, uint24(500), WETH),
            recipient: BOB,
            amountOut: 1e8,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutput(params);

        assertEqDecimal(IERC20(WBTC).balanceOf(BOB), 1e8, 8);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amount0Delta(), -1e8, 8, "amount0Delta");
        assertEqDecimal(caller.amount1Delta(), 13.582961741120595213 ether, 18, "amount1Delta");
    }
}

contract Caller is IFlashSwapperCallback, StdCheats, StdAssertions {
    address public immutable tokenIn;
    bytes public data;
    int256 public amount0Delta;
    int256 public amount1Delta;

    constructor(address _tokenIn) {
        tokenIn = _tokenIn;
    }

    function flashSwapCallback(int256 _amount0Delta, int256 _amount1Delta, address pool, bytes calldata _data)
        external
        override
    {
        uint256 amountToPay =
            IERC20(tokenIn).balanceOf(pool) + (_amount0Delta > 0 ? uint256(_amount0Delta) : uint256(_amount1Delta));

        deal(tokenIn, pool, amountToPay);

        data = _data;
        amount0Delta = _amount0Delta;
        amount1Delta = _amount1Delta;
    }
}

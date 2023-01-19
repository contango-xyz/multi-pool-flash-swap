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

    address constant DAI_WHALE = 0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8;
    address constant USDC_WHALE = 0x0A59649758aa4d66E25f08Dd01271e891fe52199;
    address constant WETH_WHALE = 0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E;
    address constant WBTC_WHALE = 0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656;

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

    function testExactInputSingle_direct() public {
        Caller caller = new Caller({_tokenIn:USDC, _whale: USDC_WHALE});

        IFlashSwapper.ExactInputSingleParams memory params = IFlashSwapper.ExactInputSingleParams({
            tokenIn: USDC,
            tokenOut: WETH,
            fee: 500,
            recipient: BOB,
            amountIn: 1500e6,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInputSingle(params);

        assertEqDecimal(IERC20(WETH).balanceOf(BOB), 0.967171538668616454 ether, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amountReceived(), 0.967171538668616454 ether, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1500e6, 6, "amountToRepay");
    }

    function testExactInputSingle_reverse() public {
        Caller caller = new Caller({_tokenIn:WETH, _whale: WETH_WHALE});

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
        assertEqDecimal(caller.amountReceived(), 1549.361628e6, 6, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1 ether, 18, "amountToRepay");
    }

    function testExactInput_2Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, _whale: WETH_WHALE});

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
        assertEqDecimal(caller.amountReceived(), 1549.166467184932744705e18, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1 ether, 18, "amountToRepay");
    }

    function testExactInput_2Pools_reverse() public {
        Caller caller = new Caller({_tokenIn:DAI, _whale: DAI_WHALE});

        IFlashSwapper.ExactInputParams memory params = IFlashSwapper.ExactInputParams({
            path: abi.encodePacked(DAI, uint24(100), USDC, uint24(500), WETH),
            recipient: BOB,
            amountIn: 1500e18,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInput(params);

        assertEqDecimal(IERC20(WETH).balanceOf(BOB), 0.967099928345655223 ether, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amountReceived(), 0.967099928345655223 ether, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1500e18, 18, "amountToRepay");
    }

    function testExactInput_3Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, _whale: WETH_WHALE});

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
        assertEqDecimal(caller.amountReceived(), 1.10409975e8, 8, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 15 ether, 18, "amountToRepay");
    }

    function testExactInput_3Pools_reverse() public {
        Caller caller = new Caller({_tokenIn:WBTC, _whale: WBTC_WHALE});

        IFlashSwapper.ExactInputParams memory params = IFlashSwapper.ExactInputParams({
            path: abi.encodePacked(WBTC, uint24(500), USDC, uint24(100), DAI, uint24(500), WETH),
            recipient: BOB,
            amountIn: 1e8,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactInput(params);

        assertEqDecimal(IERC20(WETH).balanceOf(BOB), 13.500193177529813649e18, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amountReceived(), 13.500193177529813649e18, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1e8, 8, "amountToRepay");
    }

    function testExactOutputSingle_direct() public {
        Caller caller = new Caller({_tokenIn:USDC, _whale: USDC_WHALE});

        IFlashSwapper.ExactOutputSingleParams memory params = IFlashSwapper.ExactOutputSingleParams({
            tokenIn: USDC,
            tokenOut: WETH,
            fee: 500,
            recipient: BOB,
            amountOut: 1 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutputSingle(params);

        assertEqDecimal(IERC20(WETH).balanceOf(BOB), 1 ether, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amountReceived(), 1 ether, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1550.914159e6, 6, "amountToRepay");
    }

    function testExactOutputSingle_reverse() public {
        Caller caller = new Caller({_tokenIn:WETH, _whale: WETH_WHALE});

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
        assertEqDecimal(caller.amountReceived(), 1600e6, 6, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1.032683399878123485 ether, 18, "amountToRepay");
    }

    function testExactOutput_2Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, _whale: WETH_WHALE});

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
        assertEqDecimal(caller.amountReceived(), 1600e18, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1.032813495483376696 ether, 18, "amountToRepay");
    }

    function testExactOutput_2Pools_reverse() public {
        Caller caller = new Caller({_tokenIn:DAI, _whale: DAI_WHALE});

        IFlashSwapper.ExactOutputParams memory params = IFlashSwapper.ExactOutputParams({
            path: abi.encodePacked(WETH, uint24(500), USDC, uint24(100), DAI),
            recipient: BOB,
            amountOut: 1 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutput(params);

        assertEqDecimal(IERC20(WETH).balanceOf(BOB), 1 ether, 18);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amountReceived(), 1 ether, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1551.028997854698306191e18, 18, "amountToRepay");
    }

    function testExactOutput_3Pools() public {
        Caller caller = new Caller({_tokenIn:WETH, _whale: WETH_WHALE});

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
        assertEqDecimal(caller.amountReceived(), 1e8, 8, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 13.582961741120595213 ether, 18, "amountToRepay");
    }

    function testExactOutput_3Pools_reverse() public {
        Caller caller = new Caller({_tokenIn:WBTC, _whale: WBTC_WHALE});

        IFlashSwapper.ExactOutputParams memory params = IFlashSwapper.ExactOutputParams({
            path: abi.encodePacked(WETH, uint24(500), DAI, uint24(100), USDC, uint24(500), WBTC),
            recipient: BOB,
            amountOut: 15 ether,
            data: expectedData
        });

        vm.prank(address(caller));
        flashSwapper.exactOutput(params);

        assertEqDecimal(IERC20(WETH).balanceOf(BOB), 15 ether, 8);

        assertEq(caller.data(), expectedData);
        assertEqDecimal(caller.amountReceived(), 15 ether, 18, "amountReceived");
        assertEqDecimal(caller.amountToRepay(), 1.11133904e8, 8, "amountToRepay");
    }
}

contract Caller is IFlashSwapperCallback, Test {
    IERC20 public immutable tokenIn;
    address public immutable whale;
    bytes public data;
    uint256 public amountReceived;
    uint256 public amountToRepay;

    constructor(address _tokenIn, address _whale) {
        tokenIn = IERC20(_tokenIn);
        whale = _whale;
    }

    function flashSwapCallback(uint256 _amountReceived, uint256 _amountToRepay, address pool, bytes calldata _data)
        external
        override
    {
        vm.prank(whale);
        tokenIn.transfer(pool, _amountToRepay);

        data = _data;
        amountReceived = _amountReceived;
        amountToRepay = _amountToRepay;
    }
}

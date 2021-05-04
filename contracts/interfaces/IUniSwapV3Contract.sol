// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

interface IUniSwapV3Contract {
    function createPoolV3(address _token0, address _token1, uint24 _fee) external;

    function initializePool(address _pool, uint160 sqrtPriceX96) external returns(bool success);

    function getPoolDetails() external view returns(address _token0, address _token1, uint24 fee, int24 tickSpacing, uint128 maxLiquidityPerTick, uint160 sqrtPriceX96, int24 tick);

    function getPair(address _token0, address _token1, uint24 _fee) external view returns(address pair);

    struct addLiquidityV3Params {
        address _token0;
        address _token1;
        uint24 _fee;
        int24 _tickLower;
        int24 _tickUpper;
        uint256 _amount0Desired; // 5 = 5e18 => REMIX overflow
        uint256 _amount1Desired;
        uint256 _amount0Min;
        uint256 _amount1Min;
        address _recipient;
        uint256 _deadline;
    }

    function initialLiquidityV3(addLiquidityV3Params calldata params) external returns(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function addLiquidityV3(
        uint256 _tokenId, 
        uint256 token0In, 
        uint256 token0Min, 
        uint256 token1In, 
        uint256 token1Min, 
        uint256 _deadline
    ) external returns(uint128 liquidity, uint256 amount0, uint256 amount1);

    function swapTokenForV3(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        address _recipient,
        uint256 _deadline,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
  ) external returns(uint256 amountOut);

  function approval(address token0, address token1, uint24 fee) external;

  function approvalForNFTManager() external;
}
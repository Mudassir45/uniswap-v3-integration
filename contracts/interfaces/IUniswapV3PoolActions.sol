// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3PoolActions {
    
    function initialize(uint160 sqrtPriceX96) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);

    function tickSpacing() external view returns (int24);

    function maxLiquidityPerTick() external view returns (uint128);
}

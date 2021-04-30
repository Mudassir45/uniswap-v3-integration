// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IUniswapV3PoolActions.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniSwapV3Contract.sol";

import "./libraries/TickMath.sol";
import "./libraries/LiquidityAmounts.sol";

contract UniSwapV3Contract is IUniSwapV3Contract {
  address internal constant UNISWAP_V3_FACTORY = 0x7046f9311663DB8B7cf218BC7B6F3f17B0Ea1047; // kovan
  address internal constant UNISWAP_V3_SWAP_ROUTER = 0xbBca0fFBFE60F60071630A8c80bb6253dC9D6023;
  address internal constant POSITION_MANAGER = 0xd3808aBF85aC69D2DBf53794DEa08e75222Ad9a1;
  address internal constant TEST_TOKEN_5 = 0x3f6ADe2cD50C38503AFa508b0feb59793DcE8f9F; // TKN5
  address internal constant TEST_TOKEN_10 = 0x8A50Fec9c42e77E889F99f5255e4e41c00f6E65F; // TKN10

  IUniswapV3Factory public uniswapV3Factory;
  INonfungiblePositionManager public positionManager;
  ISwapRouter public swapRouter;
  IUniswapV3PoolActions public pool;
  
  IERC20 public token0;
  IERC20 public token1;

  uint24 private constant DEFAULT_UNISWAP_FEE = 10000;
  int24 private constant MIN_TICK = -880000;
  int24 private constant MAX_TICK = 880000;

  constructor() {
    uniswapV3Factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
    swapRouter = ISwapRouter(UNISWAP_V3_SWAP_ROUTER);
    positionManager = INonfungiblePositionManager(POSITION_MANAGER);
    token0 = IERC20(TEST_TOKEN_5);
    token1 = IERC20(TEST_TOKEN_10);
  }

  function createPoolV3(address _token0, address _token1, uint24 _fee) public override {
    uniswapV3Factory.createPool(_token0, _token1, _fee); // fee: 3000
  }

  function initializePool(address _pool, uint160 sqrtPriceX96) public override returns(bool success) {
    pool = IUniswapV3PoolActions(_pool);
    pool.initialize(sqrtPriceX96);
    success = true;
  }

  function getPoolDetails() public view override returns(address _token0, address _token1, uint24 fee, int24 tickSpacing, uint128 maxLiquidityPerTick, uint160 sqrtPriceX96, int24 tick) {
    _token0 = pool.token0();
    _token1 = pool.token0();
    fee = pool.fee();
    tickSpacing = pool.tickSpacing();
    maxLiquidityPerTick = pool.maxLiquidityPerTick();
    (sqrtPriceX96, tick,,,,,) = pool.slot0();
  }

  function calculateLiquidity(int24 tickLower, int24 tickUpper, uint256 amount0Desired, uint256 amount1Desired) external view returns(uint256 liquidity) {
    (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
    uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0Desired,
                amount1Desired
            );
  }

  function getPair(address _token0, address _token1, uint24 _fee) public override view returns(address pair) {
    pair = uniswapV3Factory.getPool(_token0, _token1, _fee);
  }

  function setNewPool(address _pool) external {
    pool = IUniswapV3PoolActions(_pool);
  }

  function initialLiquidityV3(addLiquidityV3Params calldata params) public override returns(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
    token0.transferFrom(msg.sender, address(this), params._amount0Desired);
    token1.transferFrom(msg.sender, address(this), params._amount1Desired);
    
    (tokenId, liquidity, amount0, amount1) = positionManager.mint(
      INonfungiblePositionManager.MintParams({
        token0: params._token0,
        token1: params._token1,
        fee: params._fee,
        tickLower: params._tickLower,
        tickUpper: params._tickUpper,
        amount0Desired: params._amount0Desired,
        amount1Desired: params._amount1Desired,
        amount0Min: params._amount0Min,
        amount1Min: params._amount1Min,
        recipient: params._recipient,
        deadline: params._deadline
      })
    );
  }

  function addLiquidityV3(
        uint256 _tokenId, 
        uint256 token0In, 
        uint256 token0Min, 
        uint256 token1In, 
        uint256 token1Min, 
        uint256 _deadline
    ) public override returns(uint128 liquidity, uint256 amount0, uint256 amount1) {
    (liquidity, amount0, amount1) = positionManager.increaseLiquidity(
          INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: _tokenId, 
            amount0Desired: token0In, 
            amount1Desired: token1In, 
            amount0Min: token0Min, 
            amount1Min: token1Min, 
            deadline: _deadline
    })
    );
  }

  function swapTokenForV3(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        address _recipient,
        uint256 _deadline,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
  ) public override returns(uint256 amountOut) {
      amountOut = swapRouter.exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: _recipient,
            deadline: _deadline,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMinimum,
            sqrtPriceLimitX96: _sqrtPriceLimitX96
        })
      );
  }

  // Approve poolContract to spend two erc20 tokens
  function approval(address _token0, address _token1, uint24 _fee) public override {
      token0.approve(getPair(_token0, _token1, _fee), uint(-1));
      token1.approve(getPair(_token0, _token1, _fee), uint(-1));
  }

  function approvalForNFTManager() public override {
    token0.approve(POSITION_MANAGER, uint(-1));
    token1.approve(POSITION_MANAGER, uint(-1));
  }

  receive() external payable {
  }
}
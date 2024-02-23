// // SPDX-License-Identifier: MIT
// pragma solidity ^0.7.6;
// pragma abicoder v2;

// import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
// import './interfaces/IERC20Metadata.sol';
// import './interfaces/IUniswapV2Pair.sol';
// import './interfaces/IV3TwapUtilities.sol';
// import './DecentralizedIndex.sol';



// import '@openzeppelin/contracts/access/Ownable.sol';
// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
// import './interfaces/IDecentralizedIndex.sol';
// import './interfaces/IERC20Metadata.sol';
// import './interfaces/IFlashLoanRecipient.sol';
// import './interfaces/ITokenRewards.sol';
// import './interfaces/IUniswapV2Factory.sol';
// import './interfaces/IUniswapV2Router02.sol';
// import './StakingPoolToken.sol';

// abstract contract DecentralizedIndex is IDecentralizedIndex, ERC20 {
//   using SafeERC20 for IERC20;

//   uint256 public constant override FLASH_FEE_DAI = 10; // 10 DAI
//   uint256 public immutable override BOND_FEE;
//   uint256 public immutable override DEBOND_FEE;
//   address immutable V2_ROUTER;
//   address immutable V2_POOL;
//   address immutable DAI;
//   address immutable WETH;
//   IV3TwapUtilities immutable V3_TWAP_UTILS;

//   IndexType public override indexType;
//   uint256 public override created;
//   address public override lpStakingPool;
//   address public override lpRewardsToken;

//   IndexAssetInfo[] public indexTokens;
//   mapping(address => bool) _isTokenInIndex;
//   mapping(address => uint256) _fundTokenIdx;

//   bool _swapping;
//   bool _swapOn = true;

//   event FlashLoan(
//     address indexed executor,
//     address indexed recipient,
//     address token,
//     uint256 amount
//   );

//   modifier noSwap() {
//     _swapOn = false;
//     _;
//     _swapOn = true;
//   }

//   constructor(
//     string memory _name,
//     string memory _symbol,
//     uint256 _bondFee,
//     uint256 _debondFee,
//     address _lpRewardsToken,
//     address _v2Router,
//     address _dai,
//     bool _stakeRestriction,
//     IV3TwapUtilities _v3TwapUtilities
//   ) ERC20(_name, _symbol) {
//     created = block.timestamp;
//     BOND_FEE = _bondFee;
//     DEBOND_FEE = _debondFee;
//     lpRewardsToken = _lpRewardsToken;
//     V2_ROUTER = _v2Router;
//     address _v2Pool = IUniswapV2Factory(IUniswapV2Router02(_v2Router).factory())
//       .createPair(address(this), _dai);
//     lpStakingPool = address(
//       new StakingPoolToken(
//         string(abi.encodePacked('Staked ', _name)),
//         string(abi.encodePacked('s', _symbol)),
//         _dai,
//         _v2Pool,
//         lpRewardsToken,
//         _stakeRestriction ? _msgSender() : address(0),
//         _v3TwapUtilities
//       )
//     );
//     V2_POOL = _v2Pool;
//     DAI = _dai;
//     WETH = IUniswapV2Router02(_v2Router).WETH();
//     V3_TWAP_UTILS = _v3TwapUtilities;
//     emit Create(address(this), _msgSender());
//   }

//   function _transfer(
//     address _from,
//     address _to,
//     uint256 _amount
//   ) internal virtual override {
//     if (_swapOn && !_swapping) {
//       uint256 _bal = balanceOf(address(this));
//       uint256 _min = totalSupply() / 10000; // 0.01%
//       if (_from != V2_POOL && _bal >= _min && balanceOf(V2_POOL) > 0) {
//         _swapping = true;
//         _feeSwap(
//           _bal >= _min * 100 ? _min * 100 : _bal >= _min * 20 ? _min * 20 : _min
//         );
//         _swapping = false;
//       }
//     }
//     super._transfer(_from, _to, _amount);
//   }

//   function _feeSwap(uint256 _amount) internal {
//     address[] memory path = new address[](2);
//     path[0] = address(this);
//     path[1] = DAI;
//     _approve(address(this), V2_ROUTER, _amount);
//     address _rewards = StakingPoolToken(lpStakingPool).poolRewards();
//     IUniswapV2Router02(V2_ROUTER)
//       .swapExactTokensForTokensSupportingFeeOnTransferTokens(
//         _amount,
//         0,
//         path,
//         _rewards,
//         block.timestamp
//       );
//     uint256 _rewardsDAIBal = IERC20(DAI).balanceOf(_rewards);
//     if (_rewardsDAIBal > 0) {
//       ITokenRewards(_rewards).depositFromDAI(0);
//     }
//   }

//   function _transferAndValidate(
//     IERC20 _token,
//     address _sender,
//     uint256 _amount
//   ) internal {
//     uint256 _balanceBefore = _token.balanceOf(address(this));
//     _token.safeTransferFrom(_sender, address(this), _amount);
//     require(
//       _token.balanceOf(address(this)) >= _balanceBefore + _amount,
//       'TFRVAL'
//     );
//   }

//   function _isFirstIn() internal view returns (bool) {
//     return totalSupply() == 0;
//   }

//   function _isLastOut(uint256 _debondAmount) internal view returns (bool) {
//     return _debondAmount >= (totalSupply() * 98) / 100;
//   }

//   function isAsset(address _token) public view override returns (bool) {
//     return _isTokenInIndex[_token];
//   }

//   function getAllAssets()
//     external
//     view
//     override
//     returns (IndexAssetInfo[] memory)
//   {
//     return indexTokens;
//   }

//   function addLiquidityV2(
//     uint256 _idxLPTokens,
//     uint256 _daiLPTokens,
//     uint256 _slippage // 100 == 10%, 1000 == 100%
//   ) external override noSwap {
//     uint256 _idxTokensBefore = balanceOf(address(this));
//     uint256 _daiBefore = IERC20(DAI).balanceOf(address(this));

//     _transfer(_msgSender(), address(this), _idxLPTokens);
//     _approve(address(this), V2_ROUTER, _idxLPTokens);

//     IERC20(DAI).safeTransferFrom(_msgSender(), address(this), _daiLPTokens);
//     IERC20(DAI).safeIncreaseAllowance(V2_ROUTER, _daiLPTokens);

//     IUniswapV2Router02(V2_ROUTER).addLiquidity(
//       address(this),
//       DAI,
//       _idxLPTokens,
//       _daiLPTokens,
//       (_idxLPTokens * (1000 - _slippage)) / 1000,
//       (_daiLPTokens * (1000 - _slippage)) / 1000,
//       _msgSender(),
//       block.timestamp
//     );

//     // check & refund excess tokens from LPing
//     if (balanceOf(address(this)) > _idxTokensBefore) {
//       _transfer(
//         address(this),
//         _msgSender(),
//         balanceOf(address(this)) - _idxTokensBefore
//       );
//     }
//     if (IERC20(DAI).balanceOf(address(this)) > _daiBefore) {
//       IERC20(DAI).safeTransfer(
//         _msgSender(),
//         IERC20(DAI).balanceOf(address(this)) - _daiBefore
//       );
//     }
//     emit AddLiquidity(_msgSender(), _idxLPTokens, _daiLPTokens);
//   }

//   function removeLiquidityV2(
//     uint256 _lpTokens,
//     uint256 _minIdxTokens, // 0 == 100% slippage
//     uint256 _minDAI // 0 == 100% slippage
//   ) external override noSwap {
//     _lpTokens = _lpTokens == 0
//       ? IERC20(V2_POOL).balanceOf(_msgSender())
//       : _lpTokens;
//     require(_lpTokens > 0, 'LPREM');

//     uint256 _balBefore = IERC20(V2_POOL).balanceOf(address(this));
//     IERC20(V2_POOL).safeTransferFrom(_msgSender(), address(this), _lpTokens);
//     IERC20(V2_POOL).safeIncreaseAllowance(V2_ROUTER, _lpTokens);
//     IUniswapV2Router02(V2_ROUTER).removeLiquidity(
//       address(this),
//       DAI,
//       _lpTokens,
//       _minIdxTokens,
//       _minDAI,
//       _msgSender(),
//       block.timestamp
//     );
//     if (IERC20(V2_POOL).balanceOf(address(this)) > _balBefore) {
//       IERC20(V2_POOL).safeTransfer(
//         _msgSender(),
//         IERC20(V2_POOL).balanceOf(address(this)) - _balBefore
//       );
//     }
//     emit RemoveLiquidity(_msgSender(), _lpTokens);
//   }

//   function flash(
//     address _recipient,
//     address _token,
//     uint256 _amount,
//  bytes calldata _data   
//   ) external override {
//     address _rewards = StakingPoolToken(lpStakingPool).poolRewards();
//     IERC20(DAI).safeTransferFrom(
//       _msgSender(),
//       _rewards,
//       FLASH_FEE_DAI * 10 ** IERC20Metadata(DAI).decimals()
//     );
//     uint256 _balance = IERC20(_token).balanceOf(address(this));
//     IERC20(_token).safeTransfer(_recipient, _amount);
//     IFlashLoanRecipient(_recipient).callback(_data);
//     require(IERC20(_token).balanceOf(address(this)) >= _balance, 'FLASHAFTER');
//     emit FlashLoan(_msgSender(), _recipient, _token, _amount);
//   }

//   function rescueERC20(address _token) external {
//     // cannot withdraw tokens/assets that belong to the index
//     require(!isAsset(_token) && _token != address(this), 'UNAVAILABLE');
//     IERC20(_token).safeTransfer(
//       Ownable(address(V3_TWAP_UTILS)).owner(),
//       IERC20(_token).balanceOf(address(this))
//     );
//   }

//   function rescueETH() external {
//     require(address(this).balance > 0, 'NOETH');
//     _rescueETH(address(this).balance);
//   }

//   function _rescueETH(uint256 _amount) internal {
//     if (_amount == 0) {
//       return;
//     }
//     (bool _sent, ) = Ownable(address(V3_TWAP_UTILS)).owner().call{
//       value: _amount
//     }('');
//     require(_sent, 'SENT');
//   }

//   receive() external payable {
//     _rescueETH(msg.value);
//   }
// }

// contract WeightedIndex is DecentralizedIndex {
//   using SafeERC20 for IERC20;

//   IUniswapV2Factory immutable V2_FACTORY;

//   uint256 _totalWeights;

//   constructor(
//     string memory _name,
//     string memory _symbol,
//     uint256 _bondFee,
//     uint256 _debondFee,
//     address[] memory _tokens,
//     uint256[] memory _weights,
//     address _lpRewardsToken,
//     address _v2Router,
//     address _dai,
//     bool _stakeRestriction,
//     IV3TwapUtilities _v3TwapUtilities
//   )
//     DecentralizedIndex(
//       _name,
//       _symbol,
//       _bondFee,
//       _debondFee,
//       _lpRewardsToken,
//       _v2Router,
//       _dai,
//       _stakeRestriction,
//       _v3TwapUtilities
//     )
//   {
//     indexType = IndexType.WEIGHTED;
//     V2_FACTORY = IUniswapV2Factory(IUniswapV2Router02(_v2Router).factory());
//     require(_tokens.length == _weights.length, 'INIT');
//     for (uint256 _i; _i < _tokens.length; _i++) {
//       indexTokens.push(
//         IndexAssetInfo({
//           token: _tokens[_i],
//           basePriceUSDX96: 0,
//           weighting: _weights[_i],
//           c1: address(0),
//           q1: 0 // amountsPerIdxTokenX96
//         })
//       );
//       _totalWeights += _weights[_i];
//       _fundTokenIdx[_tokens[_i]] = _i;
//       _isTokenInIndex[_tokens[_i]] = true;
//     }
//     // at idx == 0, need to find X in [1/X = tokenWeightAtIdx/totalWeights]
//     // at idx > 0, need to find Y in (Y/X = tokenWeightAtIdx/totalWeights)
//     uint256 _xX96 = (FixedPoint96.Q96 * _totalWeights) / _weights[0];
//     for (uint256 _i; _i < _tokens.length; _i++) {
//       indexTokens[_i].q1 =
//         (_weights[_i] * _xX96 * 10 ** IERC20Metadata(_tokens[_i]).decimals()) /
//         _totalWeights;
//     }
//   }

//   function _getNativePriceUSDX96() internal view returns (uint256) {
//     IUniswapV2Pair _nativeStablePool = IUniswapV2Pair(
//       V2_FACTORY.getPair(DAI, WETH)
//     );
//     address _token0 = _nativeStablePool.token0();
//     (uint8 _decimals0, uint8 _decimals1) = (
//       IERC20Metadata(_token0).decimals(),
//       IERC20Metadata(_nativeStablePool.token1()).decimals()
//     );
//     (uint112 _res0, uint112 _res1, ) = _nativeStablePool.getReserves();
//     return
//       _token0 == DAI
//         ? (FixedPoint96.Q96 * _res0 * 10 ** _decimals1) /
//           _res1 /
//           10 ** _decimals0
//         : (FixedPoint96.Q96 * _res1 * 10 ** _decimals0) /
//           _res0 /
//           10 ** _decimals1;
//   }

//   function _getTokenPriceUSDX96(
//     address _token
//   ) internal view returns (uint256) {
//     if (_token == WETH) {
//       return _getNativePriceUSDX96();
//     }
//     IUniswapV2Pair _pool = IUniswapV2Pair(V2_FACTORY.getPair(_token, WETH));
//     address _token0 = _pool.token0();
//     uint8 _decimals0 = IERC20Metadata(_token0).decimals();
//     uint8 _decimals1 = IERC20Metadata(_pool.token1()).decimals();
//     (uint112 _res0, uint112 _res1, ) = _pool.getReserves();
//     uint256 _nativePriceUSDX96 = _getNativePriceUSDX96();
//     return
//       _token0 == WETH
//         ? (_nativePriceUSDX96 * _res0 * 10 ** _decimals1) /
//           _res1 /
//           10 ** _decimals0
//         : (_nativePriceUSDX96 * _res1 * 10 ** _decimals0) /
//           _res0 /
//           10 ** _decimals1;
//   }

//   function bond(address _token, uint256 _amount) external override noSwap {
//     require(_isTokenInIndex[_token], 'INVALIDTOKEN');
//     uint256 _tokenIdx = _fundTokenIdx[_token];
//     uint256 _tokensMinted = (_amount * FixedPoint96.Q96 * 10 ** decimals()) /
//       indexTokens[_tokenIdx].q1;
//     uint256 _feeTokens = _isFirstIn() ? 0 : (_tokensMinted * BOND_FEE) / 10000;
//     _mint(_msgSender(), _tokensMinted - _feeTokens);
//     if (_feeTokens > 0) {
//       _mint(address(this), _feeTokens);
//     }
//     for (uint256 _i; _i < indexTokens.length; _i++) {
//       uint256 _transferAmount = _i == _tokenIdx
//         ? _amount
//         : (_amount *
//           indexTokens[_i].weighting *
//           10 ** IERC20Metadata(indexTokens[_i].token).decimals()) /
//           indexTokens[_tokenIdx].weighting /
//           10 ** IERC20Metadata(_token).decimals();
//       _transferAndValidate(
//         IERC20(indexTokens[_i].token),
//         _msgSender(),
//         _transferAmount
//       );
//     }
//     emit Bond(_msgSender(), _token, _amount, _tokensMinted);
//   }

//   function debond(
//     uint256 _amount,
//     address[] memory,
//     uint8[] memory
//   ) external override noSwap {
//     uint256 _amountAfterFee = _isLastOut(_amount)
//       ? _amount
//       : (_amount * (10000 - DEBOND_FEE)) / 10000;
//     uint256 _percAfterFeeX96 = (_amountAfterFee * FixedPoint96.Q96) /
//       totalSupply();
//     _transfer(_msgSender(), address(this), _amount);
//     _burn(address(this), _amountAfterFee);
//     for (uint256 _i; _i < indexTokens.length; _i++) {
//       uint256 _tokenSupply = IERC20(indexTokens[_i].token).balanceOf(
//         address(this)
//       );
//       uint256 _debondAmount = (_tokenSupply * _percAfterFeeX96) /
//         FixedPoint96.Q96;
//       IERC20(indexTokens[_i].token).safeTransfer(_msgSender(), _debondAmount);
//       require(
//         IERC20(indexTokens[_i].token).balanceOf(address(this)) >=
//           _tokenSupply - _debondAmount,
//         'HEAVY'
//       );
//     }
//     emit Debond(_msgSender(), _amount);
//   }

//   function getTokenPriceUSDX96(
//     address _token
//   ) external view override returns (uint256) {
//     return _getTokenPriceUSDX96(_token);
//   }

//   function getIdxPriceUSDX96() public view override returns (uint256, uint256) {
//     uint256 _priceX96;
//     uint256 _X96_2 = 2 ** (96 / 2);
//     for (uint256 _i; _i < indexTokens.length; _i++) {
//       uint256 _tokenPriceUSDX96_2 = _getTokenPriceUSDX96(
//         indexTokens[_i].token
//       ) / _X96_2;
//       _priceX96 +=
//         (_tokenPriceUSDX96_2 * indexTokens[_i].q1) /
//         10 ** IERC20Metadata(indexTokens[_i].token).decimals() /
//         _X96_2;
//     }
//     return (0, _priceX96);
//   }
// }
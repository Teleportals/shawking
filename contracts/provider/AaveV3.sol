// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILoanProvider.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IAaveProtocolDataProvider.sol";

contract AaveV3 is ILoanProvider, Ownable {
  IPool public aavePool;
  IAaveProtocolDataProvider public dataProvider;

  address public teleporter;

  // ERC20 asset => to atoken map
  mapping(address => address) public aTokenMap;

  // ERC20 asset => to debt token map
  mapping(address => address) public debtTokenMap;

  constructor(
    address _teleporter,
    address _aavePool,
    address _dataProvider
  ) {
    teleporter = _teleporter;
    aavePool = IPool(_aavePool);
    dataProvider = IAaveProtocolDataProvider(_dataProvider);
  }

  function setTeleporter(address _teleporter) external onlyOwner {
    teleporter = _teleporter;
  }

  function setAavePool(address _aavePool) external onlyOwner {
    aavePool = IPool(_aavePool);
  }

  function setDataProvider(address _dataProvider) external onlyOwner {
    dataProvider = IAaveProtocolDataProvider(_dataProvider);
  }

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset token address to deposit.
   * @param _amount token amount to deposit.
   */
  function depositOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IERC20(_asset).approve(address(aavePool), _amount);
    aavePool.supply(_asset, _amount, _onBehalfOf, 0);
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   * @dev requires prior ERC20 'approve' of aTokens
   */
  function withdrawOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IERC20 aToken = IERC20(aTokenMap[_asset]);
    aToken.transferFrom(_onBehalfOf, address(this), _amount);
    aavePool.withdraw(_asset, _amount, teleporter);
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.
   * @param _amount token amount to borrow.
   * @dev requires user premission
   */
  function borrowOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    aavePool.borrow(_asset, _amount, 2, 0, _onBehalfOf);
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   * @dev requires prior ERC20 'approve'.
   */
  function paybackOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    aavePool.repay(_asset, _amount, 2, _onBehalfOf);
  }

  /**
   * @dev Returns the collateral and debt balance.
   * @param _collateralAsset address
   * @param _debtAssset address
   * @param user address
   */
  function getPairBalances(
    address _collateralAsset,
    address _debtAssset,
    address user
  ) external override view returns (uint256 collateral, uint256 debt) {
    (collateral, , , , , , , , ) = dataProvider.getUserReserveData(
      _collateralAsset,
      user
    );
    (, , debt, , , , , , ) = dataProvider.getUserReserveData(_debtAssset, user);
  }
}

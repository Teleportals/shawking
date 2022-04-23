// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILoanProvider {
  function depositOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function withdrawOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function paybackOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function borrowOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) external;

  function getPairBalances(
    address _collateralAsset,
    address _debtAssset,
    address user
  ) external view returns (uint256 collateral, uint256 debt);
}

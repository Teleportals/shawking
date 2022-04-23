// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILoanProvider {

  function paybackOnBehalf(address _asset, uint256 _amount, address _onBehalfOf) external;

  function depositOnBehalf(address _asset, uint256 _amount, address _onBehalfOf) external;

}
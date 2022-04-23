// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IProvider.sol";

import "../interfaces/IAaveProtocolDataProvider.sol";
import "../interfaces/IPool.sol";

contract ProviderAaveV3MATIC is IProvider {
  function _getAaveProtocolDataProvider() internal pure returns (IAaveProtocolDataProvider) {
    return IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);
  }

  function _getPool() internal pure returns (IPool) {
    return IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
  }

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    IPool aave = _getPool();

    IERC20(_asset).approve(address(aave), _amount);

    aave.supply(_asset, _amount, address(this), 0);

    aave.setUserUseReserveAsCollateral(_asset, true);
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    IPool aave = _getPool();

    aave.borrow(_asset, _amount, 2, 0, address(this));
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    IPool aave = _getPool();

    aave.withdraw(_asset, _amount, address(this));
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   */

  function payback(address _asset, uint256 _amount) external payable override {
    IPool aave = _getPool();

    IERC20(_asset).approve(address(aave), _amount);

    aave.repay(_asset, _amount, 2, address(this));
  }
}
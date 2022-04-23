// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPool.sol";

contract AaveV3 {
  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset token address to deposit.
   * @param _amount token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount, address _onBehalfOf, address _pool) internal {
    IPool aave = IPool(_pool);

    IERC20(_asset).approve(address(aave), _amount);

    aave.supply(_asset, _amount, _onBehalfOf, 0);

    aave.setUserUseReserveAsCollateral(_asset, true);
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.
   * @param _amount token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount, address _onBehalfOf, address _pool) internal {
    IPool aave = IPool(_pool);

    aave.borrow(_asset, _amount, 2, 0, _onBehalfOf);
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount, address _to, address _pool) internal {
    IPool aave = IPool(_pool);

    aave.withdraw(_asset, _amount, _to);
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.
   * @param _amount token amount to payback.
   */

  function payback(address _asset, uint256 _amount, address _onBehalfOf, address _pool) internal {
    IPool aave = IPool(_pool);

    IERC20(_asset).approve(address(aave), _amount);

    aave.repay(_asset, _amount, 2, _onBehalfOf);
  }
}
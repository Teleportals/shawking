// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILoanProvider.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IAaveProtocolDataProvider.sol";
import "../interfaces/ICErc20.sol";
import "../interfaces/ICEth.sol";

contract Compound is ILoanProvider, Ownable {
  address public constant NATIVE_ASSET =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public teleporter;

  // ERC20 asset => to ctoken map
  mapping(address => address) public cTokenMap;

  constructor(address _teleporter) {
    teleporter = _teleporter;
  }

  function setTeleporter(address _teleporter) external onlyOwner {
    teleporter = _teleporter;
  }

  /**
   * @dev Deposit native/ERC20_Token.
   * @param _asset token address to deposit.
   * @param _amount token amount to deposit.
   */
  function depositOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    address ctokenAddr = cTokenMap[_asset];
    require(ctokenAddr != address(0), "No mapping!");
    if (_asset == NATIVE_ASSET) {
      ICEth ctoken = ICEth(ctokenAddr);
      ctoken.mint{value: _amount}();
      uint256 cbal = ctoken.balanceOf(address(this));
      ctoken.transfer(_onBehalfOf, cbal);
    } else {
      IERC20(_asset).approve(ctokenAddr, _amount);
      ICErc20 ctoken = ICErc20(ctokenAddr);
      ctoken.mint(_amount);
      uint256 cbal = ctoken.balanceOf(address(this));
      ctoken.transfer(_onBehalfOf, cbal);
    }
  }

  /**
   * @notice Withdraw native/ERC20_Token.
   * @param _asset token address to withdraw.
   * @param _amount token amount to withdraw.
   * @dev requires prior ERC20 'approve' of cToken.
   * This function works around by transfering the control of the collateral receipt
   * to this contract.
   */
  function withdrawOnBehalf(
    address _asset,
    uint256 _amount,
    address _onBehalfOf
  ) public override {
    IGenCToken cToken = IGenCToken(cTokenMap[_asset]);
    require(address(cToken) != address(0), "No mapping!");
    cToken.transferFrom(_onBehalfOf, address(this), _amount);
    cToken.redeemUnderlying(_amount);
    if (_asset == NATIVE_ASSET) {
      teleporter.call{value: address(this).balance}("");
    } else {
      IERC20(_asset).transfer(teleporter, _amount);
    }
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
    //TODO
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
    address ctokenAddr = cTokenMap[_asset];

    // Check that ctoken address is set-up in mapping.
    require(ctokenAddr != address(0), "No mapping!");

    if (_asset == NATIVE_ASSET) {
      ICEth ctoken = ICEth(ctokenAddr);
      ctoken.repayBorrowBehalf{value: _amount}(_onBehalfOf);    
    } else {
      IERC20(_asset).approve(ctokenAddr, _amount);
      ICErc20 ctoken = ICErc20(ctokenAddr);
      ctoken.repayBorrowBehalf(_onBehalfOf, _amount);  
    }
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
  ) external view override returns (uint256 collateral, uint256 debt) {
    address ctokenCollateralAddr = cTokenMap[_collateralAsset];
    address ctokenDebtAddr = cTokenMap[_debtAssset];
    require(
      ctokenCollateralAddr != address(0) && ctokenDebtAddr != address(0),
      "No mapping!"
    );
    uint256 cTokenCollateralBal = IGenCToken(ctokenCollateralAddr).balanceOf(
      user
    );
    uint256 exRate = IGenCToken(ctokenCollateralAddr).exchangeRateStored();
    collateral = (exRate * cTokenCollateralBal) / 1e18;
    debt = IGenCToken(ctokenDebtAddr).borrowBalanceStored(user);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  function allocateTo(address _owner, uint256 _amount) external;
  function mint(uint256 value) external returns (bool);
}
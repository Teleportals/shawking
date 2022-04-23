// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Teleporter is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Supply
{
    constructor() ERC1155("") {}

    function initiateLoanTranser(
        uint256 targetChainID,
        address loanProviderA,
        address loanProviderB
    ) external {
        // 1.- check and validate inputs
        // 2.- payback debt on-behalf of user
        // 3.- withdraw collateral on-behalf of user
        // 4.- keep control of user collateral
        // 5.- construct xcall to bridge collateral
        // 6.- make xcall
    }

    function completeLoanTranser(
        uint256 targetChainID,
        address loanProviderA,
        address loanProviderB
    ) external {
        // 1.- check destination and target
        // 2.- open debt position
        // 3.- make position claimable
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Adds liquidity to the teleporter.
     * @param asset 
     */
    function addLiquidity(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) public {
      if (onBehalfOf == address(0)) {
        _mint(msg.sender, uint256(asset), amount, "");
      } else {
        _mint(onBehalfOf, uint256(asset), amount, "");
      }
    }

    /**
     * 
     */
    function removeLiquidity(
        address asset,
        uint256 amount,
        address onBehalfOf,
        bytes memory signedMessage
    ) public {
      if (onBehalfOf == address(0)) {
        _burn(msg.sender, uint256(asset), amount);
      } else {
        // Check message
        
      }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

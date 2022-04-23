// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IConnext.sol";
import "./interfaces/ILoanProvider.sol";

contract Teleporter is ERC1155, Ownable, Pausable, ERC1155Supply {

  address public constant NATIVE_ASSET =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  IConnext public immutable connext;

  // domain(chain) => loan provider address => bool 
  mapping(uint32 => mapping(address => bool)) public isLoanProvider;

  // collateral address => debt address
  mapping(address => address ) public isSupportedPair;

  constructor(address _connext) ERC1155("") {
    connext = IConnext(_connext);
  }

  function initiateLoanTranser(
    uint32 originDomain,
    uint32 destinationDomain,
    address loanProviderA,
    address loanProviderB,
    address collateralAsset,
    uint256 collateralAmount,
    address debtAsset,
    uint256 debtAmount
  ) external {
    // 1.- Checks and input validation
    // 1.1 Check that loan provider addresses and domains (chains) are valid.
    require(
      isLoanProvider[originDomain][loanProviderA] && isLoanProvider[destinationDomain][loanProviderB], 
      "Wrong Address!"
    );
    // 1.2 Check there is enough liquidity to initiate loan transfer.
    require(IERC20(debtAsset).balanceOf(address(this)) > debtAmount,"No liquidity!");
    // 1.3 Check if loan transfer pair is supported
    require(isSupportedPair[collateralAsset] == debtAsset, "No pair support!");
    
    // 2.- Pay back debt on-behalf of user
    //TODO add support for NATIVE_ASSET as 'debtAsset'
    ILoanProvider loanProvider = ILoanProvider(loanProviderA);
    IERC20(debtAsset).transfer(loanProviderA, debtAmount); 
    loanProvider.paybackOnBehalf(debtAsset, debtAmount, msg.sender);

    // 3.- Transfer collateral of user

    // 4.- keep control of user collateral
    //TODO withdraw on behalf of user

    // 5.- construct xcall to bridge collateral

    //Approve tokens for bridging
    IERC20 token = IERC20(collateralAsset);
    token.approve(address(connext), collateralAmount);

    bytes4 selector = bytes4(keccak256("completeLoanTransfer(address,address,uint256,address,uint256)"));

    bytes memory callData = abi.encodeWithSelector(
    selector,
    loanProviderB,
    collateralAsset,
    collateralAmount,
    debtAsset,
    debtAmount
    );

    IConnext.CallParams memory callParams = IConnext.CallParams({
      //TODO "to" for destiantion contract
      to: address(0),
      callData: callData,
      originDomain: originDomain,
      destinationDomain: destinationDomain
    });

    IConnext.XCallArgs memory xcallArgs = IConnext.XCallArgs({
      params: callParams,
      transactingAssetId: collateralAsset,
      amount: collateralAmount
    });

    // 6.- make xcall

    connext.xcall(xcallArgs);
  }

  function completeLoanTranser(
    address loanProviderB,
    address collateralAsset,
    uint256 collateralAmount,
    address debtAsset,
    uint256 debtAmount
  ) external {
    // 1.- check destination and target
    // 2.- open debt position
    // 3.- make position claimable
  }

  function setLoanProvider(uint32 _domain, address _loanProvider, bool status) external onlyOwner {
    isLoanProvider[_domain][_loanProvider] = status;
  }

  function setSupportedPair(address _collateralAddress, address _debtAddress) external onlyOwner {
    isSupportedPair[_collateralAddress] = _debtAddress;
  }

  function setURI(string memory newuri) external onlyOwner {
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
   * @param asset address
   * @param amount to 
   * @param onBehalfOf another user address. Pass ZERO address if not applicable.
   * @dev call requires prior ERC20 'approve" 
   */
  function addLiquidity(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) public {
    if (onBehalfOf == address(0)) {
      IERC20(asset).transferFrom(msg.sender, address(this), amount);
      _mint(msg.sender, uint256(uint160(asset)), amount, "");
    } else {
      IERC20(asset).transferFrom(onBehalfOf, address(this), amount);
      _mint(onBehalfOf, uint256(uint160(asset)), amount, "");
    }
  }

  /**
   * @notice Removes liquidity from the teleporter.
   * @param asset address
   * @param amount to 
   * @param onBehalfOf another user address. Pass ZERO address if not applicable.
   */
  function removeLiquidity(
    address asset,
    uint256 amount,
    address onBehalfOf,
    bytes memory signedMessage
  ) public {
    if (onBehalfOf == address(0)) {
      _burn(msg.sender, uint256(uint160(asset)), amount);
      IERC20(asset).transfer(msg.sender, amount);
    } else {
      //TODO Check message
      signedMessage;
      _burn(onBehalfOf, uint256(uint160(asset)), amount);
      IERC20(asset).transfer(onBehalfOf, amount);
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

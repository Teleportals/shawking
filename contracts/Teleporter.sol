// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IConnext.sol";
import "./interfaces/ILoanProvider.sol";
import "./interfaces/IExecutor.sol";

contract Teleporter is ERC1155, Ownable, Pausable, ERC1155Supply {

  address public constant NATIVE_ASSET =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  IConnext public immutable connext;

  // domain(chain) => teleporter address
  mapping(uint32 => address) public teleporters;

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
    require(teleporters[destinationDomain] != address(0), "No teleporter!");
    // 1.2 Check there is enough liquidity to initiate loan transfer.
    require(IERC20(debtAsset).balanceOf(address(this)) > debtAmount,"No liquidity!");
    // 1.3 Check if loan transfer pair is supported
    require(isSupportedPair[collateralAsset] == debtAsset, "No pair support!");
    
    // 2.- Pay back debt on-behalf of user
    //TODO add support for NATIVE_ASSET as 'debtAsset'
    ILoanProvider loanProvider = ILoanProvider(loanProviderA);
    IERC20(debtAsset).transfer(loanProviderA, debtAmount); 
    loanProvider.paybackOnBehalf(debtAsset, debtAmount, msg.sender);

    // 3.- Transfer and withdraw collateral from user to Teleporter control
    loanProvider.withdrawOnBehalf(collateralAsset, collateralAmount, msg.sender);
  
    // 4.- Construct arguments for bridging (Connext)
    bytes4 selector = bytes4(keccak256("completeLoanTransfer(uint32,address,address,uint256,address,uint256,address)"));

    bytes memory callData = abi.encodeWithSelector(
    selector,
    originDomain,
    loanProviderB,
    collateralAsset,
    collateralAmount,
    debtAsset,
    debtAmount,
    msg.sender
    );

    IConnext.CallParams memory callParams = IConnext.CallParams({
      //TODO "to" for destiantion contract
      to: teleporters[destinationDomain],
      callData: callData,
      originDomain: originDomain,
      destinationDomain: destinationDomain
    });

    IConnext.XCallArgs memory xcallArgs = IConnext.XCallArgs({
      params: callParams,
      transactingAssetId: collateralAsset,
      amount: collateralAmount
    });

    // 6.- Make external call to execute bridge operation (Connext)
    if (collateralAsset != NATIVE_ASSET) {
    //Approve tokens for bridging
      IERC20(collateralAsset).approve(address(connext), collateralAmount);
      connext.xcall(xcallArgs);
    } else {
      connext.xcall{value: collateralAmount}(xcallArgs);
    }
  }

  function completeLoanTranser(
    uint32 originDomain,
    address loanProviderB,
    address collateralAsset,
    uint256 collateralAmount,
    address debtAsset,
    uint256 debtAmount,
    address user
  ) external {
    // 1.- check destination and target
    require(
      // origin domain of the source contract
      IExecutor(msg.sender).origin() == originDomain,
      "Expected origin domain"
    );
    require(
      // msg.sender of xcall from the origin domain
      IExecutor(msg.sender).originSender() == teleporters[originDomain],
      "Expected origin domain contract"
    );
    // 2.- open debt position
    // 2.1 - deposti
    ILoanProvider loanProvider = ILoanProvider(loanProviderB);
    IERC20(collateralAsset).transfer(loanProviderB, collateralAmount); 
    loanProvider.depositOnBehalf(collateralAsset, collateralAmount, user);

    // 2.2 - borrow
    loanProvider.borrowOnBehalf(debtAsset, debtAmount, user);

    // 3.- make position claimable
  }

  function setLoanProvider(uint32 _domain, address _loanProvider, bool status) external onlyOwner {
    isLoanProvider[_domain][_loanProvider] = status;
  }

  function setSupportedPair(address _collateralAddress, address _debtAddress) external onlyOwner {
    isSupportedPair[_collateralAddress] = _debtAddress;
  }

  function setTeleporter(uint32 _domain, address _teleporter) external onlyOwner {
    teleporters[_domain] = _teleporter;
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

  /// Hooks

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

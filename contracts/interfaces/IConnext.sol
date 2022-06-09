// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IConnext {
  /**
  * @notice These are the call parameters that will remain constant between the
  * two chains. They are supplied on `xcall` and should be asserted on `execute`
  * @property to - The account that receives funds, in the event of a crosschain call,
  * will receive funds if the call fails.
  * @param to - The address you are sending funds (and potentially data) to
  * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
  * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
  * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
  * @param recovery - The address to send funds to if your `Executor.execute call` fails
  * @param callback - The address on the origin domain of the callback contract
  * @param callbackFee - The relayer fee to execute the callback
  * @param forceSlow - If true, will take slow liquidity path even if it is not a permissioned call
  * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
  */
  struct CallParams {
    address to;
    bytes callData;
    uint32 originDomain;
    uint32 destinationDomain;
    address recovery;
    address callback;
    uint256 callbackFee;
    bool forceSlow;
    bool receiveLocal;
  }

  /**
  * @notice The arguments you supply to the `xcall` function called by user on origin domain
  * @param params - The CallParams. These are consistent across sending and receiving chains
  * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
  * or the representational asset
  * @param amount - The amount of transferring asset the tx called xcall with
  * @param relayerFee - The amount of relayer fee the tx called xcall with
  */
  struct XCallArgs {
    CallParams params;
    address transactingAssetId; // Could be adopted, local, or wrapped
    uint256 amount;
    uint256 relayerFee;
  }

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);
}

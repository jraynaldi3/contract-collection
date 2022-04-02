//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./MultiSig.sol";

/**
* @author Julius Raynaldi
* @title Multi Signature Wallet Contract Factory
* @dev contract to make new Multi Signature Wallet {MultiSig} contract
* implementation of {IMultiSigFactory} 
 */
contract MultiSigFactory is IMultiSigFactory{
    using Counters for Counters.Counter;

    event WalletCreated(uint id, string name, address walletAddress);
    Counters.Counter private _walletIds;

    Wallet[] wallets;

    function createWallet(string memory _name, address[] memory owners) external override returns(address){
        address wallet = address(new MultiSig(owners));
        uint newId = _walletIds.current();
        wallets.push(Wallet({
            id: newId,
            name: _name,
            walletAddress : wallet
        }));
        _walletIds.increment();
        emit WalletCreated(newId, _name, address(wallet));
        return wallet;
    }

    function getAllWallets() external view override returns(Wallet[] memory){
        return wallets;
    }
    
    function _msgSender() external view override returns(address){
        return msg.sender;
    }
}
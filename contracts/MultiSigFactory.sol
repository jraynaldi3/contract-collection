//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./MultiSig.sol";
import "hardhat/console.sol";

/**
* @author Julius Raynaldi
* @title Multi Signature Wallet Contract Factory
* @dev contract to make new Multi Signature Wallet {MultiSig} contract
* implementation of {IMultiSigFactory} 
 */
contract MultiSigFactory {
    using Counters for Counters.Counter;

    event WalletCreated(uint id, string name, address walletAddress);
    Counters.Counter private _walletIds;

    struct Wallet {
        uint id; //id of wallet
        string name; //name of wallet
        address walletAddress; //the address of wallet
    }

    Wallet[] wallets;

    function createWallet(string memory _name, address[] memory owners) external returns(address){
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

    function getAllWallet() external view returns(Wallet[] memory){
        return wallets;
    }

    /*
    //TODO make interface of {MultiSig} 
    function getAllWalletBySender() external view returns(Wallet[] memory){
        address[] memory senderWallet;
        for (uint i = 0; i<wallets.length; i++){
            if(wallet.)
        }
    }
    */
    
    function _msgSender() external view returns(address){
        return msg.sender;
    }
}
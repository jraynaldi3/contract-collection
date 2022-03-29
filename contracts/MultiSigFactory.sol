//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./MultiSig.sol";
import "hardhat/console.sol";

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
        console.log(wallet);
        return wallet;
    }

    function _msgSender() external view returns(address){
        return msg.sender;
    }
}
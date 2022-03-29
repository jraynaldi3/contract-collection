//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./MultiSigWallet.sol";

contract MultiSigWalletFactory {
    using Counters for Counters.Counter;

    Counters.Counter private _walletIds;

    struct Wallet {
        uint id; //id of wallet
        string name; //name of wallet
        address walletAddress; //the address of wallet
    }

    Wallet[] wallets;

    function newWallet(string memory _name, address[] memory owners) external payable {
        MultiSig wallet = new MultiSig(owners);
        wallets.push(Wallet({
            id: _walletIds.current(),
            name: _name,
            walletAddress : address(wallet)
        }));
    }
}
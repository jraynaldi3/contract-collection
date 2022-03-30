//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/** 
* @dev interface contract to access {MultiSigFactory} from other contract
*/

interface IMultiSigFactory {
    struct Wallet {
        uint id; //id of wallet
        string name; //name of wallet
        address walletAddress; //the address of wallet
    }

    /**
    * @dev create new multi signature wallet
    * @param _name name of wallet (use for front end)
    * @param owners Array of address become an initial "Owner" role
    * @return address address of new multi signature wallet
     */
    function createWallet(string memory _name, address[] memory owners) external returns(address);

    /**
    *@dev get all wallet created
    *@return Wallet all wallet created
    */
    function getAllWallets() external view returns(Wallet[] memory);

    /**
    * @notice return address of sender of {MultiSigFactory}
    * @dev for constructor of {MultiSig} to pass "Super" Role to msg.sender
    * @return address msg.sender address
     */
    function _msgSender() external view returns(address);


}
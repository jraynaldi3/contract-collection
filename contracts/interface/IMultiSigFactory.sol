//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/** 
* @dev interface contract to access {MultiSigFactory} from other contract
*/

interface IMultiSigFactory {
    function createWallet(string memory _name, address[] memory owners) external returns(address);

    function _msgSender() external view returns(address);
}
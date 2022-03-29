//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/IMemberList.sol";

/**
*@author Julius Raynaldi 
*@dev Update to {AccessControlEnumerable} for adding {isMember}
*@notice this can be use for help {MultiSigFactory} to find wallet of msg.sender own
* This Contract is using for user interface
* When Login in contract factory people will see which MultiSigWallet they participate to
*/
contract MemberManagement is IMemberList, AccessControlEnumerable {

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter memberCount;

    mapping(address => bool) public isMember;
    mapping(address => uint256) public roleByNum;
    
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        isMember[account] = true;
        (,roleByNum[account]) = SafeMath.tryAdd(roleByNum[account], 1);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        (,roleByNum[account]) = SafeMath.trySub(roleByNum[account], 1);
        if(roleByNum[account] < 1) isMember[account] = false;
    }

    function checkIsMember(address account) external view override returns(bool) {
        return isMember[account];
    } 
}
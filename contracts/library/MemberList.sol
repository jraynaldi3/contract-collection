//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
* This Contract is using for user interface
* When Login in contract factory people will see which MultiSigWallet they participate to
*/
contract MemberList is AccessControl {

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter memberCount;

    mapping(address => bool) public isMember;
    mapping(address => uint256) public roleByNum;
    
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
        isMember[account] = true;
        (,roleByNum[account]) = SafeMath.tryAdd(roleByNum[account], 1);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)){
        _revokeRole(role,account);
        (,roleByNum[account]) = SafeMath.trySub(roleByNum[account], 1);
        if(roleByNum[account] < 1) isMember[account] = false;
    }

    function renounceRole(bytes32 role, address account) public virtual override{
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);

        (,roleByNum[account]) = SafeMath.trySub(roleByNum[account],1);
        if(roleByNum[account] < 1) isMember[account] = false;
    }

    function _setupRole(bytes32 role, address account) internal virtual override {
        _grantRole(role, account);
        isMember[account] = true;
        (,roleByNum[account]) = SafeMath.tryAdd(roleByNum[account], 1);
    }
}
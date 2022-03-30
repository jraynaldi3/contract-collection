//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IMemberManagement is IAccessControlEnumerable {
   function checkIsMember(address account) external view returns(bool);
}
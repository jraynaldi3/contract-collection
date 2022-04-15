//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.4;

import "./IMemberManagement.sol";

interface IMultiSig is IMemberManagement {
    function tokenSubmitTransaction (
            address _token, 
            address _to, 
            uint _amount,
            uint duration, 
            string calldata _data
        ) external ;

    function ethSubmitTransaction (address _to, uint _amount,uint duration, string calldata _data) external;

    function approveTransaction (uint _id) external;

    function revokeApproval(uint _id) external;

    function executeTransaction(uint _id) external;

    function getApproveCount(uint _id) external view returns(uint);

    function setQuorum (uint num) external;

    function isApprovedBy(uint _id, address _sender) external view returns(bool);
}
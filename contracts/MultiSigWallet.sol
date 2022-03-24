//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
*@author: Julius Raynaldi
*Inspired by solidity-by-example.org
*for practice purpose
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

/*What Difference?
* 1. using Openzeppelin AccesControl instead of define owner manualy
* 2. using more role that will be usefull in more wide case
* 3. using IERC20.sol for transfer another token than ETH
* 4. using custom Error
* 5. using struct to store member data
*/

interface MultiSigIERC20 is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract MultiSig is AccessControl{
    event SubmitTransaction (uint id,string tokenSymbol, address to, uint amount, string data);
    event ApproveTransaction (uint id, address approver);
    event RevokeTransaction (uint id, address revoker);
    event ExecuteTransaction (uint id, address executor);

    using Counters for Counters.Counter;
    Counters.Counter public _transactionId;

    error Unauthorized();
    error AlreadyApproved();
    error NotApprovedYet();

    struct Transaction {
        //transaction id
        uint id;
        //token symbol for more information
        string tokenSymbol;
        //token address
        address tokenAddress;
        // transfer to address
        address to;
        // how much wanna transfer
        uint amount;
        // data if necessary
        string data;
        // address of who submit the transaction
        address submitter;
        // numbot of address that aporved the transacrion
        uint approveCount;
    }

    struct Member {
        bytes32[] roles; //roles of that member
        address memberAddress; //mmeber address
    }

    //show that an address approved yet or not
    mapping(uint => mapping(address => bool)) approvedBy;

    Transaction[] public transactions;
    Member[] public members;


    constructor (address[] memory owners) {
        console.log(msg.sender);
        _setupRole("Super", msg.sender);
        console.log(hasRole("Super", msg.sender));
        _setRoleAdmin("Owner", "Super");
        _setRoleAdmin("Approver", "Owner");
        grantRole("Owner", msg.sender);
        
        for (uint i; i < owners.length;i++){
             grantRole("Owner", owners[i]);
             grantRole("Approver", owners[i]);
        }
        
    }

    /*
    * @dev theres a problem when ETH itself is not an ERC-20 token so i decide to separate these with 2
    * function instead of using conditional operation
    *
    * @params 
    * - _token = token address which will be transfered
    * - _to = the address that will be recive transfer from this address
    * - _amount = amount of token will be transfered 
    * - _data = data for this transaction
    */
    function tokenSubmitTransaction (address _token, address _to, uint _amount, string calldata _data) public onlyRole("Owner") {
        uint _id = _transactionId.current();

        transactions.push(Transaction({
            id:_id,
            tokenSymbol:MultiSigIERC20(_token).symbol(),
            tokenAddress:_token,
            to:_to,
            amount:_amount,
            data:_data,
            submitter:_msgSender(),
            approveCount:0
        }));

        emit SubmitTransaction(_id,MultiSigIERC20(_token).symbol(), _to, _amount, _data);

        _transactionId.increment();
    }

    /*
    *@dev use this function to transfer ETH from this contract
    * 
    *@params 
    * - _to = address that will recive 
    * - _amount = amount ETH will be transfered
    * - _data = transaction data
    */
    function ethSubmitTransaction (address _to, uint _amount, string calldata _data) public onlyRole("Owner"){
        uint _id = _transactionId.current();

        transactions.push(Transaction({
            id : _id,
            tokenSymbol: "ETH",
            tokenAddress: address(0),
            to: _to,
            amount:_amount,
            data:_data,
            submitter:_msgSender(),
            approveCount:0
        }));

        emit SubmitTransaction(_id,"ETH",_to,_amount,_data);

        _transactionId.increment();
    }

    function approveTransaction (uint _id) public {
        if (!hasRole("Approver", msg.sender) && !hasRole("Owner",msg.sender)) {
            revert Unauthorized();
        }
        if (approvedBy[_id][msg.sender]==true) revert AlreadyApproved();

        Transaction memory transaction = transactions[_id];

        transaction.approveCount ++;
        approvedBy[_id][msg.sender] = true;

        emit ApproveTransaction(_id, msg.sender);
    }

    function revokeApproval(uint _id) public {
        if (!hasRole("Approver", msg.sender) && !hasRole("Owner",msg.sender)) {
            revert Unauthorized();
        }
        if (approvedBy[_id][msg.sender]==true) revert NotApprovedYet();

        Transaction memory transaction = transactions[_id];
        transaction.approveCount --;
        approvedBy[_id][msg.sender] = false;

        emit RevokeTransaction(_id, msg.sender);
    }
}
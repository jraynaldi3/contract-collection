//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/IMultiSigFactory.sol";
import "./library/MemberManagement.sol";

/**
*Inspired by solidity-by-example.org (look at What Difference? comment section)
*for practice purpose
*you can use it but make sure to double check the code before deployment
*
* What Difference?
* 1. using Openzeppelin AccesControlEnumerable instead of define owner manualy
* 2. using more role that will be usefull in more wide case
* 3. using IERC20.sol for transfer another token than ETH
* 4. using custom Error
* 5. using struct to store member data (indevelopment)
* 6. add duration of transaction
* 7. only submitter of transaction can execute transaction
* 8. (UPDATE) Quorum now using percentage of total member (using openzeppelin AccessControlEnumerable)
*/

interface MultiSigIERC20 is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

/**
* @title Multi Signature Wallet
* @author Julius Raynaldi
* @notice contract of multi signature wallet, some role can submit a transaction but need other people to 
* sign before the transaction can be executed
*
* Roles:
* - "Owner" role work as admin who can submit and execute transaction for wallet 
* - "Approver" role work as member who can only approve transaction without approve
*       from this role(not fullfill the quorum) "Owner" cannot execute transaction
* - "Super" role work as member manager this role can promote "Approver" to "Owner" (for utility purpose)
*
* Transaction Life Cycle:
* "Owner" Submit transaction -> "Approver" and "Owner" can approve transaction -> "Owner" Execute transaction
*/
contract MultiSig is MemberManagement{
    event SubmitTransaction (uint id,string tokenSymbol, address to, uint amount, string data,uint endDate);
    event ApproveTransaction (uint id, address approver);
    event RevokeApproval (uint id, address revoker);
    event ExecuteTransaction (uint id, address executor);

    using Counters for Counters.Counter;
    Counters.Counter private _transactionId;

    error Unauthorized();
    error AlreadyApproved();
    error NotApprovedYet();
    error WrongTime();
    error AlreadyExecuted();

    uint public quorum; //an minimal approval to be executed

    struct Transaction {
        uint id; //transaction id
        string tokenSymbol; //token symbol for more information
        address tokenAddress; //token address
        address to; // transfer to address
        uint amount; // how much wanna transfer
        string data; // data if necessary
        address submitter; // address of who submit the transaction   
        uint approveCount; // numbot of address that aporved the transaction       
        uint endDate; // when transaction end
        bool executed; // is transaction executed
    }

    mapping(uint => mapping(address => bool)) approvedBy; //that address approved the transaction or not

    Transaction[] public transactions;
    
    constructor (address[] memory owners,address sender) payable {
        _setupRole("Super", sender);
        _setupRole("Super", msg.sender);
        _setRoleAdmin("Owner", "Super");
        _setRoleAdmin("Approver", "Owner");
        grantRole("Owner", sender);
        
        for (uint i; i < owners.length;i++){
             grantRole("Owner", owners[i]);
        }

        setQuorum(50);
        renounceRole("Super", msg.sender);
    }

    //Require should met when interaction with approval (approveTransaction & revokeApproval)
    modifier approvalReq(uint _id) {
        if(block.timestamp > transactions[_id].endDate) revert WrongTime();
        if (!hasRole("Approver", msg.sender) && !hasRole("Owner",msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    /**
    * @dev theres a problem when ETH itself is not an ERC-20 token so i decide to separate these with 2
    * function instead of using conditional operation
    *
    *  
    * @param _token = token address which will be transfered
    * @param _to = the address that will be recive transfer from this address
    * @param _amount = amount of token will be transfered 
    * @param duration = duration of transaction
    * @param _data = data for this transaction
    *
    * emit a {SubmitTransaction} event
    */
    function tokenSubmitTransaction (
            address _token, 
            address _to, 
            uint _amount,
            uint duration, 
            string calldata _data
        ) public onlyRole("Owner") {
        uint _id = _transactionId.current();
        uint endAt = block.timestamp + duration;

        transactions.push(Transaction({
            id:_id,
            tokenSymbol:MultiSigIERC20(_token).symbol(),
            tokenAddress:_token,
            to:_to,
            amount:_amount,
            data:_data,
            submitter:_msgSender(),
            approveCount:0,
            endDate: endAt,
            executed: false
        }));        

        emit SubmitTransaction(_id,MultiSigIERC20(_token).symbol(), _to, _amount, _data, endAt);
        _transactionId.increment();
    }

    /**
    *@dev use this function to transfer ETH from this contract
    *
    *@param _to  address that will recive 
    *@param _amount amount ETH will be transfered
    *@param duration duration of transaction 
    *@param _data transaction data
    *
    * emit {SubmitTransaction} event
    */
    function ethSubmitTransaction (address _to, uint _amount,uint duration, string calldata _data) public onlyRole("Owner"){
        uint _id = _transactionId.current();
        uint endAt = block.timestamp + duration;

        transactions.push(Transaction({
            id : _id,
            tokenSymbol: "ETH",
            tokenAddress: address(0),
            to: _to,
            amount:_amount,
            data:_data,
            submitter:_msgSender(),
            approveCount:0,
            endDate: endAt,
            executed: false
        }));

        emit SubmitTransaction(_id,"ETH",_to,_amount,_data,endAt);

        _transactionId.increment();
    }

    /** 
    *@dev function to approve transaction
    *@param _id id of transaction
    * emit a {ApproveTransaction} event
    *
    *Require :
    * - Transaction duration not ended yet (see {approvalReq})
    * - msg.sender is one of "Approver" or "Owner" (see {approvalReq})
    * - msg.sender not approved the transaction yet
    */
    function approveTransaction (uint _id) public approvalReq(_id) {
        if (approvedBy[_id][msg.sender]==true) revert AlreadyApproved();

        Transaction storage transaction = transactions[_id];

        transaction.approveCount = transaction.approveCount +1;
        approvedBy[_id][msg.sender] = true;

        emit ApproveTransaction(_id, msg.sender);
    }

    /**
    *@dev function to revoke approval
    *@param _id id of transaction
    * emit a {RevokeApproval} event
    *
    *Require :
    * - Transaction duration not ended yet (see {approvalReq})
    * - msg.sender is one of "Approver" or "Owner" (see {approvalReq})
    * - msg.sender has approved the transaction 
    */
    function revokeApproval(uint _id) public approvalReq(_id){
        if (approvedBy[_id][msg.sender]==false) revert NotApprovedYet();

        Transaction storage transaction = transactions[_id];

        transaction.approveCount --;
        approvedBy[_id][msg.sender] = false;

        emit RevokeApproval(_id, msg.sender);
    }

    /**
    *@dev function to execute transaction 
    *@param _id id of transaction
    *emit a {ExecuteTransaction} event
    *
    *Requires:
    * - Transaction duration has been ended 
    * - executor must be submitter of transaction
    * - Transaction not executed yet
    * - Approval fullfill the quorum 
    */
    function executeTransaction(uint _id) public {
        
        Transaction storage transaction = transactions[_id];
        if (block.timestamp < transaction.endDate) revert WrongTime();
        if (transaction.submitter != msg.sender) revert Unauthorized();
        if (transaction.executed == true) revert AlreadyExecuted();
        
        require(transaction.approveCount > minimalApproval(), "Not Approved");
        if (transaction.tokenAddress == address(0)) {
            (bool success , ) = address(transaction.to).call{value: transaction.amount}("");
            require (success,"Failed to execute");
        } else {
            IERC20(transaction.tokenAddress).transfer(transaction.to, transaction.amount);
        }
        transaction.executed = true;
        emit ExecuteTransaction(_id, msg.sender);
    }

    /** 
    *@dev function for show the approveCount of transaction
    *@param _id id of transaction
    *@return uint number of people already approve of transaction
    */
    function getApproveCount(uint _id) external view returns(uint) {
        return transactions[_id].approveCount;
    }

    /**
    *@dev function for set the quorum of transaction, ONLY for "Super" role 
    *@param num new quorum count for set
    */
    function setQuorum (uint num) public{
        if(!hasRole("Super",msg.sender)) revert Unauthorized();
        quorum = num;
    }

    /**
    *@dev approvalCount should fullfill the minimalApproval 
    *@return minimal a minimal number of approval before transaction can be executed
     */
    function minimalApproval() internal view returns(uint minimal){
        uint totalMember = getRoleMemberCount("Owner") + getRoleMemberCount("Approver");
        minimal = totalMember * quorum / 100;
    }

    /**
    *@dev help the front end 
    *@return transactions all transaction this wallet ever made
    */
    function getAllTransactions() external view returns(Transaction[] memory){
        return transactions;
    }
}
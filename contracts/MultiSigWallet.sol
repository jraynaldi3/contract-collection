//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
*@author: Julius Raynaldi
*Inspired by solidity-by-example.org (look at What Difference? comment section)
*for practice purpose
*you can use it but make sure to double check the code before deployment
*
*
*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";
import "./library/MemberList.sol";

/*What Difference?
* 1. using Openzeppelin AccesControl instead of define owner manualy
* 2. using more role that will be usefull in more wide case
* 3. using IERC20.sol for transfer another token than ETH
* 4. using custom Error
* 5. using struct to store member data (indevelopment)
* 6. add duration of transaction
* 7. only submitter of transaction can execute transaction
* 8. add quorum but only one role can set Quorum
*/

interface MultiSigIERC20 is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

/*
* A multi signature wallet 
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
contract MultiSig is MemberList{
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
    
    constructor (address[] memory owners) payable {
        console.log(msg.sender);
        _setupRole("Super", msg.sender);
        console.log(hasRole("Super", msg.sender));
        _setRoleAdmin("Owner", "Super");
        _setRoleAdmin("Approver", "Owner");
        grantRole("Owner", msg.sender);
        
        for (uint i; i < owners.length;i++){
             grantRole("Owner", owners[i]);
        }

        setQuorum(1);
        
    }

    //Require should met when interaction with approval (approveTransaction & revokeApproval)
    modifier approvalReq(uint _id) {
        if(block.timestamp > transactions[_id].endDate) revert WrongTime();
        if (!hasRole("Approver", msg.sender) && !hasRole("Owner",msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    /*
    * @dev theres a problem when ETH itself is not an ERC-20 token so i decide to separate these with 2
    * function instead of using conditional operation
    *
    * @params 
    * - _token = token address which will be transfered
    * - _to = the address that will be recive transfer from this address
    * - _amount = amount of token will be transfered 
    * - duration = duration of transaction
    * - _data = data for this transaction
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

    /*
    *@dev use this function to transfer ETH from this contract
    * 
    *@params 
    * - _to = address that will recive 
    * - _amount = amount ETH will be transfered
    * - duration = duration of transaction 
    * - _data = transaction data
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

    //function to approve transaction
    // @param id of transaction
    function approveTransaction (uint _id) public approvalReq(_id) {
        if (approvedBy[_id][msg.sender]==true) revert AlreadyApproved();

        Transaction storage transaction = transactions[_id];

        transaction.approveCount = transaction.approveCount +1;
        approvedBy[_id][msg.sender] = true;

        emit ApproveTransaction(_id, msg.sender);
    }

    //function to revoke approval
    // @param id of transaction
    function revokeApproval(uint _id) public approvalReq(_id){
        if (approvedBy[_id][msg.sender]==false) revert NotApprovedYet();

        Transaction storage transaction = transactions[_id];

        transaction.approveCount --;
        approvedBy[_id][msg.sender] = false;

        emit RevokeApproval(_id, msg.sender);
    }

    //function to execute transaction 
    //@param id of transaction
    function executeTransaction(uint _id) public {
        
        Transaction storage transaction = transactions[_id];
        if (block.timestamp < transaction.endDate) revert WrongTime();
        if (transaction.submitter != msg.sender) revert Unauthorized();
        if (transaction.executed == true) revert AlreadyExecuted();
        
        require(transaction.approveCount > quorum, "Not Approved");
        if (transaction.tokenAddress == address(0)) {
            (bool success , ) = address(transaction.to).call{value: transaction.amount}("");
            require (success,"Failed to execute");
        } else {
            IERC20(transaction.tokenAddress).transfer(transaction.to, transaction.amount);
        }
        transaction.executed = true;
        emit ExecuteTransaction(_id, msg.sender);
    }

    //function for show the approveCount of transaction
    function getApproveCount(uint _id) external view returns(uint) {
        return transactions[_id].approveCount;
    }

    //function for set the quorum of transaction, ONLY for "Super" role 
    function setQuorum (uint num) public{
        if(!hasRole("Super",msg.sender)) revert Unauthorized();
        quorum = num;
    }

}
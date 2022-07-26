// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SuperEscrow is ReentrancyGuard {

    event BuyAccepted(uint256 id, uint256 price, address buyer);
    event AccessCodeSent(uint256 id, address seller);

    struct Transaction {
        uint256 id;
        string url;
        address buyer;
        address seller;
        string passcode;
        uint256 price;
        bool isPaid;
        bool isSentToSeller;
    }

    mapping(uint256 => Transaction) transactions;
    uint256 nextId = 1;

    address private admin;
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin can execute this');
        _;
    }

    function sell(string memory _url, uint256 _price) public {
        Transaction memory newTx = Transaction(
            nextId,
            _url,
            address(0),
            msg.sender,
            '',
            _price,
            false,
            false
        );
        transactions[nextId] = newTx;
        nextId++;
    }


    function buy(uint256 _id) public payable {
        require(msg.value >= transactions[_id].price, 'Payment not enough');
        require(nextId > _id, 'Not existing');
        require(transactions[_id].isPaid != true, 'Already bought');
        require(transactions[_id].isSentToSeller != true, 'Already claimed');

        transactions[_id].buyer = msg.sender;
        transactions[_id].isPaid = true;
        emit BuyAccepted(_id, transactions[_id].price, msg.sender);
    }

    function sendCode(uint256 _id, string memory passcode) public nonReentrant {
        require(transactions[_id].isPaid, 'Transaction not yet paid');
        require(transactions[_id].seller == msg.sender, 'Only seller can send code');
        require(transactions[_id].isSentToSeller == false, 'Already processed');

        (bool sent, ) = transactions[_id].seller.call{value: transactions[_id].price}("");
        require(sent, "Failed to send Ether");

        transactions[_id].passcode = passcode;
        transactions[_id].isSentToSeller = true;
        emit AccessCodeSent(_id, msg.sender);
    }

    function getUrl(uint256 _id, string memory passcode) public view returns(string memory) {
        require(transactions[_id].isPaid, 'Transaction not yet paid');
        require(transactions[_id].isSentToSeller, 'Not yet sent to seller');
        require(transactions[_id].buyer == msg.sender, 'Only buyer can get url');
        require(keccak256(bytes(transactions[_id].passcode)) == keccak256(bytes(passcode)), 'Passcode is incorrect');

        return transactions[_id].url;
    }

    // for testing purposes only
    function getTxInfo(uint256 _id) public view onlyAdmin returns (Transaction memory) {
        return transactions[_id];
    }
}
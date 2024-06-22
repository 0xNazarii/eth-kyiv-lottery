// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Lottery {
    struct Ticket {
        uint256 value;
        bool revealed;
        bytes signature;
    }

    event LotteryEntered(address entrant, uint256 deposited);
    event NumberRevealed(address entrant, uint256 number);

    uint256 public immutable enterDeadline;
    uint256 public immutable revealDeadline;

    uint256 public luckyNumber;
    uint256 public totalShares;

    uint256 public entrantCount;
    uint256 public revealCount;

    mapping(address =>  Ticket) public tickets;
    address[] public entrants;

    constructor() {
        enterDeadline = block.timestamp + 1 days;
    }

    function enter(bytes calldata signature) external payable {
        require(block.timestamp < enterDeadline, "The lottery is closed for new entrants");
        require(entrants[msg.sender].value == 0, "You have already entered the lottery");
        require(msg.value >= 0.01 ether, "You must deposit at least 0.01 ether to enter the lottery");

        tickets[msg.sender] = Ticket({
            value: msg.value,
            revealed: false,
            signature: signature
        });

        entrants.push(msg.sender);

        emit LotteryEntered(msg.sender, msg.value);
    }

    function reveal(uint256 numberToReveal) external {
        require(block.timestamp >= enterDeadline, "The lottery is still open for entrants");

        // If this is the first reveal, set the reveal deadline
        if (revealDeadline == 0) {
            revealDeadline = block.timestamp + 1 days;
        }

        require(block.timestamp < revealDeadline, "The lottery has ended");

        Ticket memory ticket = tickets[msg.sender];

        require(ticket.value > 0, "You have not entered the lottery");
        require(!ticket.revealed, "You have already revealed your lucky number");
        require(isValidLuckyNumber(msg.sender, numberToReveal, ticket.signature), "Invalid signature for lucky number");

        ticket.revealed = true;

        tickets[msg.sender] = ticket;
        totalShares += ticket.value;
        revealCount++;

        emit NumberRevealed(msg.sender, numberToReveal);
    }

    function isValidLuckyNumber(address entrant, uint256 number, bytes calldata signature) public view returns (bool) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            bytes.concat("My lucky number is ", bytes(Strings.toString(number)))
        );

        return SignatureChecker.isValidSignatureNow(entrant, hash, signature);
    }
}

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

    /// @dev The deadline for entering the lottery. Deadline is 1 day after contract creation.
    uint256 public immutable enterDeadline;

    /// @dev The deadline for revealing lucky numbers. Deadline is 1 day after the first reveal.
    uint256 public revealDeadline;

    /// @dev The XOR of all lucky numbers revealed by entrants. Used to determine the winner.
    uint256 public luckyNumber;

    /// @dev The total amount of ether deposited by entrants who have revealed their lucky number.
    uint256 public totalShares;

    /// @dev The number of entrants who have revealed their lucky number. Used to end the lottery before the reveal deadline.
    uint256 public revealCount;

    mapping(address =>  Ticket) public tickets;
    address[] public entrants;

    constructor() {
        enterDeadline = block.timestamp + 1 days;
    }

    function enter(bytes calldata signature) external payable {
        require(block.timestamp < enterDeadline, "The lottery is closed for new entrants");
        require(tickets[msg.sender].value == 0, "You have already entered the lottery");
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
        luckyNumber ^= numberToReveal;

        emit NumberRevealed(msg.sender, numberToReveal);
    }

    function winner() public view returns (address) {
        if(revealCount != entrants.length && block.timestamp < revealDeadline) {
            return address(0);
        }

        uint256 winnerNumber = luckyNumber % totalShares;

        for (uint256 i = 0; i < entrants.length; i++) {
            address entrant = entrants[i];
            Ticket memory ticket = tickets[entrant];

            if (ticket.revealed) {
                if (winnerNumber < ticket.value) {
                    return entrant;
                }

                winnerNumber -= ticket.value;
            }
        }

        return entrants[luckyNumber % entrants.length];
    }

    function claim() external {
        address winnerAddress = winner();

        require(winnerAddress != address(0), "The winner has not been determined");
        require(winnerAddress == msg.sender, "You are not the winner");

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether to the winner");
    }

    function isValidLuckyNumber(address entrant, uint256 number, bytes memory signature) public view returns (bool) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            bytes.concat("My lucky number is ", bytes(Strings.toString(number)))
        );

        return SignatureChecker.isValidSignatureNow(entrant, hash, signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Lottery {
    struct Entrant {
        bytes signature;
        uint256 deposited;
        bool revealed;
    }

    event LotteryEntered(address entrant, uint256 deposited);
    event NumberRevealed(address entrant, uint256 number);

    uint256 public immutable enterDeadline;
    uint256 public immutable revealDeadline;

    uint256 public luckyNumber;
    uint256 public totalShares;

    uint256 public entrantCount;
    uint256 public revealCount;

    mapping(address => Entrant) public entrants;

    constructor() {
        enterDeadline = block.timestamp + 1 days;
        revealDeadline = enterDeadline + 1 days;
    }

    function enter(bytes calldata signature) external payable {
        require(block.timestamp < enterDeadline, "The lottery is closed for new entrants");
        require(entrants[msg.sender].deposited == 0, "You have already entered the lottery");
        require(msg.value >= 0.01 ether, "You must deposit at least 0.01 ether to enter the lottery");

        entrants[msg.sender] = Entrant({
            signature: signature,
            deposited: msg.value,
            revealed: false
        });

        emit LotteryEntered(msg.sender, msg.value);
    }

    function reveal(uint256 numberToReveal, bytes calldata signature) external {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

//        require(block.timestamp >= unlockTime, "You can't withdraw yet");
//        require(msg.sender == owner, "You aren't the owner");
//
//        emit Withdrawal(address(this).balance, block.timestamp);
//
//        owner.transfer(address(this).balance);
    }

    function isValidLuckyNumber(address entrant, uint256 number, bytes calldata signature) public view returns (bool) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            bytes.concat("My lucky number is ", bytes(Strings.toString(number)))
        );

        return SignatureChecker.isValidSignatureNow(entrant, hash, signature);
    }
}

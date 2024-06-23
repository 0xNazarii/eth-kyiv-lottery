# Lottery - bounty by Peanut Trade - ETHKyiv2024

## Bounty Description

>Develop a smart contract where users lock their ETH until a specified timestamp. After this timestamp, any participants of the lottery can trigger the win() method and claim the reward (all locked ETH). The probability of being among the winners is proportional to the amount of ETH deposited.

## *The Randomness Problem*

Relying on any values that can be read during the execution of a smart contract is not secure. For example, using `block.timestamp` or `block.difficulty` to generate randomness is not secure because anyone can manipulate these values to their advantage.

The simplest solution for that would be to use [Chainlink VRF (Verifiable Random Function)](https://docs.chain.link/vrf) to generate a random number that can be used to determine the winner of the lottery.

## The Oracle-less Solution

To make the thing work without using Chainlink VRF, we can use a commit-reveal scheme. The idea is to have participants commit to a random number hash and then reveal the number. The lucky number is then calculated using revealed numbers.

## Testing

To test the smart contract, you can use the following steps:

1. Install dependencies:

```bash
yarn install
```

2. Run tests:

```bash
yarn test
```

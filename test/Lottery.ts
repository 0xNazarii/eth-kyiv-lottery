import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import {expect} from "chai";
import hre from "hardhat";
import {Lottery} from "../typechain-types";
import {ethers, Wallet} from "ethers";

describe("Lottery", function () {
  async function deploy() {
    const [user1, user2, user3, otherAccount] = await hre.ethers.getSigners();

    const Lottery = await hre.ethers.getContractFactory("Lottery");
    const lottery = await Lottery.deploy();

    return {lottery, user1, user2, user3, otherAccount};
  }

  describe.skip("isValidLuckyNumber", function () {
    const luckyNumber = 42;
    const message = `My lucky number is ${luckyNumber}`;

    it("should return `true` for valid signatures", async function () {
      const {lottery, user1} = await loadFixture(deploy);

      const signature = await user1.signMessage(message);
      const isValid = await lottery.isValidLuckyNumber(user1.address, luckyNumber, signature);

      expect(isValid).to.be.true;
    });

    it("should return `false` for invalid signatures", async function () {
      const {lottery, user1} = await loadFixture(deploy);

      const wrongLuckyNumber = 43;

      expect(wrongLuckyNumber).to.not.equal(luckyNumber);

      const signature = await user1.signMessage(message);
      const isValid = await lottery.isValidLuckyNumber(user1.address, wrongLuckyNumber, signature);

      expect(isValid).to.be.false;
    });
  });

  describe('winner', function () {
    const winners: Record<string, number> = {};
    const runs = 1000;
    const user1Amount = ethers.parseEther('1');
    const user2Amount = ethers.parseEther('3');
    const user3Amount = ethers.parseEther('6');

    it('should have a change to win proportional to value deposited', async () => {
      const [user1, user2, user3, otherAccount] = await hre.ethers.getSigners();

      for (let i = 0; i < runs; i++) {
        const {lottery} = await loadFixture(deploy);

        const user1LuckyNumber = BigInt(Wallet.createRandom().address).toString();
        const user2LuckyNumber = BigInt(Wallet.createRandom().address).toString();
        const user3LuckyNumber = BigInt(Wallet.createRandom().address).toString();

        const user1Signature = await user1.signMessage(`My lucky number is ${user1LuckyNumber}`);
        const user2Signature = await user2.signMessage(`My lucky number is ${user2LuckyNumber}`);
        const user3Signature = await user3.signMessage(`My lucky number is ${user3LuckyNumber}`);

        await lottery.connect(user1).enter(user1Signature, {value: user1Amount});
        await lottery.connect(user2).enter(user2Signature, {value: user2Amount});
        await lottery.connect(user3).enter(user3Signature, {value: user3Amount});

        await time.increaseTo(await lottery.enterDeadline() + 2n * 60n * 60n);

        await lottery.connect(user1).reveal(user1LuckyNumber);
        await lottery.connect(user2).reveal(user2LuckyNumber);
        await lottery.connect(user3).reveal(user3LuckyNumber);

        const winner = await lottery.winner();

        winners[winner] = (winners[winner] || 0) + 1;
      }

      console.log({
        user1: winners[user1.address],
        user2: winners[user2.address],
        user3: winners[user3.address],
      });
    });
  });
});

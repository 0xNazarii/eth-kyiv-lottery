import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import {Lottery} from "../typechain-types";

describe("Lottery", function () {
  async function deploy() {
    const [user1, otherAccount] = await hre.ethers.getSigners();

    const Lottery = await hre.ethers.getContractFactory("Lottery");
    const lottery = await Lottery.deploy();

    return { lottery, user1, otherAccount };
  }

  describe("isValidLuckyNumber", function () {
    const luckyNumber = 42;
    const message = `My lucky number is ${luckyNumber}`;

    it("should return `true` for valid signatures", async function () {
      const { lottery, user1 } = await loadFixture(deploy);

      const signature = await user1.signMessage(message);
      const isValid = await lottery.isValidLuckyNumber(user1.address, luckyNumber, signature);

      expect(isValid).to.be.true;
    });

    it("should return `false` for invalid signatures", async function () {
      const { lottery, user1 } = await loadFixture(deploy);

      const wrongLuckyNumber = 43;

      expect(wrongLuckyNumber).to.not.equal(luckyNumber);

      const signature = await user1.signMessage(message);
      const isValid = await lottery.isValidLuckyNumber(user1.address, wrongLuckyNumber, signature);

      expect(isValid).to.be.false;
    });
  });
});

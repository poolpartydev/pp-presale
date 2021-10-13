// We import Chai to use its asserting functions here.
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { ethers, network } from "hardhat";
import { PpPresale } from "../typechain/PpPresale";
import { TestToken } from "../typechain/TestToken";

chai.use(solidity);
const { expect } = chai;
/**
 * 
 * @note Difference between opening and closing time should be <100
 * @note Hardcap should be =10
 */
describe("LSD Bag Factory", function () {
    let Presale: PpPresale;
    let owner: SignerWithAddress;
    let receiver: SignerWithAddress;
    let addr2: SignerWithAddress;
    let addr3: SignerWithAddress;
    let addr4: SignerWithAddress;
    let addrs: SignerWithAddress[];
    let Token1: TestToken;


    beforeEach(async function () {

        const PpPresaleFactory = await ethers.getContractFactory("PpPresale");
        [owner, receiver, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();


        const ERC20Factory = await ethers.getContractFactory("TestToken");
        Token1 = await (ERC20Factory.deploy()) as TestToken;

        Presale = (await PpPresaleFactory.deploy(Token1.address, receiver.address)) as PpPresale;
        // send 200M tokens into the presale
        await Token1.transfer(Presale.address, ethers.utils.parseEther("200000000"))
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
    
            expect(await Presale.owner()).to.equal(owner.address);
        });

        it("Should set rate to 950k", async function () {
            expect(await Presale.rate()).to.equal(950000);
        });
    });
    const whitelistAddress2 = async () => await Presale.whitelistAddress(addr2.address);

    const buyFrom = (account: SignerWithAddress) => async (amount: string) => {
        const tx = await account.sendTransaction({
            value: ethers.utils.parseEther(amount),
            to: Presale.address,
            gasLimit: 5000000
        });
        await tx.wait();
    }

    const buyAddress2 = (amount: string) => buyFrom(addr2)(amount);

    const increaseTimeBy100Sec = async () => {
        await network.provider.send("evm_increaseTime", [100]);
        await network.provider.send("evm_mine");
    }
    describe("Presale participation", () => {
        it("Should whitelist address", async () => {
            await Presale.whitelistAddress(addr2.address);
            expect(await Presale.whitelisted(addr2.address)).to.be.true;
        })
        it("Should whitelist multiple addresses", async () => {
            const addresses = [addr2, addr3, addr4].map(a => a.address);
            await Presale.whitelistMultipleAddresses(addresses);
            Promise.all(addresses.map(async addr => expect(await Presale.whitelisted(addr)).to.be.true))
        })
        it("Should allocate tokens to participant", async () => {
            await whitelistAddress2();
            await buyAddress2("1");
            expect(await Presale.balanceOf(addr2.address)).to.be.equal(ethers.utils.parseEther("950000"));
        })
        it("Should allow multiple contributions", async () => {
            await whitelistAddress2();
            await buyAddress2("0.5");
            expect(await Presale.balanceOf(addr2.address)).to.be.equal(ethers.utils.parseEther("475000"));
            await buyAddress2("0.25");
            await buyAddress2("0.125");
            await buyAddress2("0.125");
            expect(await Presale.balanceOf(addr2.address)).to.be.eq(ethers.utils.parseEther("950000"));

        })
        it("Should send raised funds to receiver", async () => {
            await whitelistAddress2();
            const receiverBefore = await receiver.getBalance();

            await buyAddress2("1");

            expect(await receiver.getBalance()).to.be.eq(receiverBefore.add(ethers.utils.parseEther("1")));
        })
        it("Shouldn't allow bigger than max contribution", async () => {
            await whitelistAddress2();
            await expect(buyAddress2("1.1")).to.be.reverted;
        })
        it("Shouldn't allow not whitelisted address to participate", async () => {
            await expect(buyAddress2("1")).to.be.reverted;
        })
        it("Shouldn't allow participation after time's up", async () => {
            await whitelistAddress2();

            await increaseTimeBy100Sec();
            await expect(buyAddress2("1")).to.be.reverted;

        })
        it("Shouldn't allow participation when hardcap is reached", async () => {
            // @note works only with Hard Cap set to 10
            await Presale.whitelistMultipleAddresses(addrs.slice(0,10).map(a => a.address));
            await Promise.all(addrs.slice(0, 10).map(addr => buyFrom(addr)("1")));

            await expect(buyAddress2("1")).to.be.reverted;
        })
    })

    describe("Token claim", () => {
        it("Should send tokens to contributor after finalization", async () => {
            await whitelistAddress2();
            await buyAddress2("1");

            await increaseTimeBy100Sec();
            await Presale.finalize();

            await Presale.connect(addr2).withdrawTokens(addr2.address);
            expect(await Token1.balanceOf(addr2.address)).to.be.eq(ethers.utils.parseEther("950000"));

        })
        it("Should send all tokens to participant with multiple contributions", async () => {
            await whitelistAddress2();
            await buyAddress2("0.5");
            await buyAddress2("0.5");

            await increaseTimeBy100Sec();
            await Presale.finalize();

            await Presale.connect(addr2).withdrawTokens(addr2.address);
            expect(await Token1.balanceOf(addr2.address)).to.be.eq(ethers.utils.parseEther("950000"));


        })
        it("Shouldn't allow to claim tokens before finalization", async () => {
            await whitelistAddress2();
            await buyAddress2("1");

            await increaseTimeBy100Sec();
            await expect(Presale.connect(addr2).withdrawTokens(addr2.address)).to.be.reverted;
        })
    })
});

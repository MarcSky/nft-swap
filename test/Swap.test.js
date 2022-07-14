const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("NFT", function () {
    let owner, user1, user2;
    let nftSwap;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        const NFTSwap = await ethers.getContractFactory("NFTSwap", owner);
        nftSwap = await NFTSwap.deploy();
        await nftSwap.deployed();
    });

    it("swap", async function () {
        const NFT1 = await ethers.getContractFactory("NFT1", owner);
        const token1 = await NFT1.deploy();
        await token1.deployed();
        let txn = await token1.connect(user1).mint();
        await txn.wait();

        const NFT2 = await ethers.getContractFactory("NFT2", owner);
        const token2 = await NFT2.deploy();
        await token2.deployed();
        txn = await token2.connect(user2).mint();
        await txn.wait();


        txn = await token1.connect(user1).setApprovalForAll(nftSwap.address, true);
        txn.wait()

        txn = await token2.connect(user2).setApprovalForAll(nftSwap.address, true);
        txn.wait()

        let owner_token1_before = await token1.ownerOf(0);
        console.log("token 0 from NFT1 owner:", owner_token1_before);

        let owner_token2_before = await token2.ownerOf(0);
        console.log("token 0 from NFT2 owner:", owner_token2_before);

        txn = await nftSwap.connect(user1).createSwap(user2.address, token1.address, token2.address, 0, 0);
        txn.wait();
        await nftSwap.connect(user2).acceptSwap(1);

        let owner_token1_after = await token1.ownerOf(0);
        let owner_token2_after = await token2.ownerOf(0);

        expect(owner_token1_after).to.be.eq(owner_token2_before);
        expect(owner_token2_after).to.be.eq(owner_token1_before);
    });

});

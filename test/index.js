const { ethers, deployments, upgrades } = require("hardhat")
const { expect } = require("chai")
describe("test upgrade", async function () {

    it("should able to deploy", async function () {

        // 1、部署业务合约
        await deployments.fixture(["deployNftAuction"])
        const nftAuctionProxy = await deployments.get("NftAuctionProxy")
        // 2、调用createAuction方法，创建拍卖
        const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);
        await nftAuction.createAuction(
            100 * 1000,
            ethers.parseEther("0.01"),
            ethers.ZeroAddress,
            1
        )
        const auction = await nftAuction.auctions(0);
        console.log("创建拍卖成功", auction);
        const implAddress1 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
        // 3、升级合约
        await deployments.fixture(["upgradeNftAuction"])
        const implAddress2 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);

        // 4、读取合约的auction[0]
        const aucton2 = await nftAuction.auctions(0);
        console.log("升级后读取拍卖成功", aucton2);

        const nftAuctionV2 = await ethers.getContractAt("NftAuctionV2", nftAuctionProxy.address);
        const hello = await nftAuctionV2.testHello();
        console.log("hello::", hello);
        console.log("implAddress1::", implAddress1, "\nimplAddress2::", implAddress2);
        expect(auction.startTime).to.be.equal(aucton2.startTime);
        expect(implAddress1).not.to.be.equal(implAddress2);
    })
})
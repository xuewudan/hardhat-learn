const { ethers, deployments } = require("hardhat");
const { expect } = require("chai");

describe("Auction Test", async function () {

    it("should able ok", async function () {
        await main();
    });
});

async function main() {
    await deployments.fixture(["deployNftAuction"]);
    const nftAuctionProxy = await deployments.get("NftAuctionProxy")
    console.log("NftAuctionProxy address:", nftAuctionProxy.address);

    const [signer, buyer] = await ethers.getSigners();

    // 1、部署业务合约
    const TestERC721 = await ethers.getContractFactory("TestERC721");
    const testERC721 = await TestERC721.deploy();
    await testERC721.waitForDeployment();
    const testERC721Address = await testERC721.getAddress();
    console.log("TestERC721 address::", testERC721Address);
    // mint 10个 NFT
    for (let i = 0; i < 10; i++) {
        await testERC721.mint(signer.address, i + 1);
    }
    const tokenId = 1;
    // 2、调用createAuction方法，创建拍卖
    const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);

    // 给代理合约授权
    await testERC721.connect(signer).setApprovalForAll(nftAuctionProxy.address, true);
    await nftAuction.createAuction(
        10,
        ethers.parseEther("0.01"),
        testERC721Address,
        tokenId
    );

    const auction = await nftAuction.auctions(0);

    console.log("创建拍卖成功", auction);

    // 3、购买者参与拍卖
    await nftAuction.connect(buyer).placeBid(0, {
        value: ethers.parseEther("0.01")
    });

    // 结束拍卖
    // 等待10秒
    await new Promise(resolve => setTimeout(resolve, 10 * 1000));

    console.log("signer::", signer)
    await nftAuction.connect(signer).endAuction(0);


    // 验证结果
    const auctionResult = await nftAuction.auctions(0);
    console.log("拍卖结果：", auctionResult);
    expect(auctionResult.highestBidder).to.be.equal(buyer.address);
    expect(auctionResult.highestBid).to.be.equal(ethers.parseEther("0.01"));

    // 验证NFT归属
    const newOwner = await testERC721.ownerOf(tokenId);
    console.log("NFT新归属：", newOwner);
    expect(newOwner).to.be.equal(buyer.address);
}
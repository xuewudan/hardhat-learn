const { ethers, upgrades } = require("hardhat");
const path = require("path");
const fs = require("fs");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { save } = deployments;
    const deployer = await getNamedAccounts();
    console.log("部署用户的地址：", deployer)
    // 读取.chche/proxyNftAuction.json文件

    const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");
    const storeData = fs.readFileSync(storePath, "utf-8");
    const { proxyAdress, implementationAddress, abi } = JSON.parse(storeData);

    // 升级版的业务合约
    const NftAuctionProxyV2 = await ethers.getContractFactory("NftAuctionV2");
    // 升级代理合约
    const nftAuctionProxyV2 = await upgrades.upgradeProxy(proxyAdress, NftAuctionProxyV2, {
        call: { fn: 'initialize' }
    });
    await nftAuctionProxyV2.waitForDeployment();

    const proxyAddressV2 = await nftAuctionProxyV2.getAddress();

    // 保存合约地址
    fs.writeFileSync(
      storePath,
      JSON.stringify({
        proxyAdress: proxyAddressV2,
        implementationAddress: implementationAddress,
        abi: abi,
      })
    );

    save("nftAuctionProxyV2", {
        abi: abi,
        address: proxyAddressV2
    });

};
module.exports.tags = ["upgradeNftAuction"];
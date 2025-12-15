const { deployments, upgrades, ethers } = require("hardhat");

const fs = require("fs")
const path = require("path")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { save } = deployments;
    const { deployer } = await getNamedAccounts();
    console.log("部署用户的地址：", deployer)
    const NftAuction = await ethers.getContractFactory("NftAuction")

    // 通过代理部署合约
    // 数组里面传的是初始化所需要的参数，没有参数就不传
    const nftAuctionProxy = await upgrades.deployProxy(NftAuction, [
        //  "0x0000000000000000000000000000000000000000",
        //  100 * 1000,
        //  ethers.parseEther("0.00000000000000000001"),
        //  ethers.ZeroAddress,
        //  1
    ],
        { initializer: 'initialize' }); // 指定初始化函数名称：initialize

    await nftAuctionProxy.waitForDeployment();
    const proxyAdress = await nftAuctionProxy.getAddress();
    console.log("NftAuction代理合约地址：", proxyAdress);
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAdress);
    console.log("NftAuction实现合约地址：", implementationAddress);


    const storePath = path.resolve(__dirname, "./.cache/proxyNftAuction.json");

    fs.writeFileSync(storePath,
        JSON.stringify({
            proxyAdress,
            implementationAddress,
            abi: NftAuction.interface.format("json")
        }));

    await save("NftAuctionProxy",
        {
            abi: NftAuction.interface.format("json"),
            address: proxyAdress
            // args: [],
            // log: true
        }
    );


    // await deploy('MyContract', {
    //     from: deployer,
    //     args: ['Hello'],
    //     log: true,
    // });
};
module.exports.tags = ['deployNftAuction'];



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract NftAuction is Initializable, UUPSUpgradeable {
    // 结构体
    struct Auction {
        address seller; // 卖家
        uint256 startPrice; // 起拍价
        uint256 startTime; // 起拍开始时间
        uint256 duration; // 拍卖持续时间
        bool ended; // 是否结束
        address highestBidder; // 当前最高价的地址
        uint256 highestBid; // 当前最高价
        // NFT合约地址
        address nftContract;
        // NFT的ID
        uint256 tokenId;
        // 参与支付的资产类型，0地址是ETH，1地址是ERC20代币
        address tokenAddress;
    }

    // 状态变量
    mapping(uint256 => Auction) public auctions;

    // 下一个拍卖ID
    uint256 public nextAuctionId;

    // 管理员地址
    address public admin;

    AggregatorV3Interface internal priceETHFeed;

    // constructor() {
    //     admin = msg.sender;
    // }
    // constructor() {
    //     admin = msg.sender;
    // }

    function initialize() public initializer {
        admin = msg.sender;
    }

    function setPriceETHFeed(address _priceFeed) external {
        // require(msg.sender == admin, "Only admin can set price feed");
        priceETHFeed = AggregatorV3Interface(_priceFeed);
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        // prettier-ignore
        (
      /* uint80 roundId */
      ,
      int256 answer,
      /*uint256 startedAt*/
      ,
      /*uint256 updatedAt*/
      ,
      /*uint80 answeredInRound*/
    ) = priceETHFeed.latestRoundData();
        return answer;
    }

    function getLatestPrice() public returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceETHFeed.latestRoundData();
        // emit PriceUpdated(price);
        return price;
    }

    function createAuction(
        uint256 _duration,
        uint256 _startPrice,
        address _nftContract,
        uint256 _tokenId
    ) public {
        // 只有管理员才能创建拍卖
        require(msg.sender == admin, "Only admin can create auctions");
        // 检查参数
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_duration >= 10, "Duration must be greater than 10s");

        // 转换NFT到合约
        IERC721(_nftContract).approve(address(this), _tokenId);

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            startPrice: _startPrice,
            startTime: block.timestamp,
            duration: _duration,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            nftContract: _nftContract,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });
        nextAuctionId++;
    }

    // 参与竞拍
    // TODO: ERC20也能参加竞价
    function placeBid(
        uint256 _auctionId,
        uint256 amount,
        address _tokenAddress
    ) external payable {
        // 统一的价值尺度
        // 1ETH = ? 美金
        // 1USDC = ? 美金
        require(msg.value >= 1 ether, "Bid must be at least 1 ether");
        Auction storage auction = auctions[_auctionId];

        // 检查拍卖是否仍在进行中
        require(!auction.ended, "Auction has been ended");
        require(
            block.timestamp < auction.startTime + auction.duration,
            "Auction time has expired"
        );

        // 检查出价是否有效
        require(
            msg.value > auction.highestBid,
            "Bid must be higher than current highest bid"
        );
        require(
            msg.value >= auction.startPrice,
            "Bid must be at least the starting price"
        );

        // 退款给前一个最高出价者
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        // 更新当前最高出价信息
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }

    // 拍卖结束
    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        // console.log("endAuction", auction.startTime + auction.duration);
        // 判断拍卖是否结束
        require(
            !auction.ended &&
                block.timestamp > auction.startTime + auction.duration,
            "Auction not yet ended"
        );
        // 转移NFT给最高出价者
        IERC721(auction.nftContract).transferFrom(
            admin,
            auction.highestBidder,
            auction.tokenId
        );
        // 转移资金给卖家
        // payable(address(this)).transfer(address(this).balance);
        // 标记拍卖为结束
        auction.ended = true;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        require(msg.sender == admin, "Only admin can upgrade");
    }
}

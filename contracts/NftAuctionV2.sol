// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NftAuctionV2 is Initializable {
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
    }

    // 状态变量
    mapping(uint256 => Auction) public auctions;

    // 下一个拍卖ID
    uint256 public nextAuctionId;

    // 管理员地址
    address public admin;

    // constructor() {
    //     admin = msg.sender;
    // }

    function initialize() public initializer {
        admin = msg.sender;
    }

    function createAuction(
        uint256 _startPrice,
        uint256 _duration,
        address _nftContract,
        uint256 _tokenId
    ) public {
        // 只有管理员才能创建拍卖
        require(msg.sender == admin, "Only admin can create auctions");
        // 检查参数
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            startPrice: _startPrice,
            startTime: block.timestamp,
            duration: _duration,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            nftContract: _nftContract,
            tokenId: _tokenId
        });
        nextAuctionId++;
    }

    // 参与竞拍
    function placeBid(uint256 _auctionId) external payable {
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
            msg.value > auction.startPrice,
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

    function testHello() public pure returns (string memory) {
        return "Hello, NftAuction!";
    }
}

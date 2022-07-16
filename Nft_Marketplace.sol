// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NftMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable private _owner;
    uint256 constant LISTING_FEES = 1 ether;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private _idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool sold
    );

    constructor() {
        _owner = payable(msg.sender);
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable {
        require(
            msg.sender != address(0),
            "NftMarketplace:sender is zero address"
        );
        require(
            nftContract != address(0),
            "NftMarketplace:nftContract is zero address"
        );
        require(tokenId > 0, "NftMarketplace:tokenId < 0");
        require(price > 0, "NftMarketplace:price < 0");
        require(msg.value == LISTING_FEES, "msg.value < LISTING_FEES");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        _idToMarketItem[itemId] = MarketItem({
            itemId: itemId,
            nftContract: nftContract,
            tokenId: tokenId,
            seller: payable(msg.sender),
            owner: payable(address(0)),
            price: price,
            sold: false
        });

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    function createMarketSale(uint256 tokenId, address nftContract)
        public
        payable
        nonReentrant
    {
        MarketItem storage token = _idToMarketItem[tokenId];
        require(msg.sender != token.owner, "NftMarketplace: owner cannot buy");
        require(
            msg.value == token.price,
            "NftMarketplace:msg.value < token.price"
        );
        token.seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            token.tokenId
        );
        token.owner = payable(msg.sender);
        token.sold = true;
        _itemsSold.increment();
        uint256 contractBalance = address(this).balance;
        _owner.transfer(contractBalance);
    }

    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        require(
            msg.sender != address(0),
            "NftMarketplace: sender is zero address"
        );
        uint totalItemCount = _itemIds.current();
        uint itemCount;
        uint currentIndex;

        for (uint i = 1; i <= totalItemCount; i++) {
            if (_idToMarketItem[i].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 1; i <= itemCount; i++) {
            if (_idToMarketItem[i].seller == msg.sender) {
                MarketItem storage currentItem = _idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}

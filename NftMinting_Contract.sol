// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NftMinter is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public _marketplaceAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address marketplaceAddress_
    ) ERC721(_name, _symbol) {
        _marketplaceAddress = marketplaceAddress_;
    }

    function createToken(string memory tokenURI) public returns (uint256) {
        require(bytes(tokenURI).length > 0, "NftMinter: tokenUri.length < 0");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        setApprovalForAll(_marketplaceAddress, true);
        return newTokenId;
    }
}

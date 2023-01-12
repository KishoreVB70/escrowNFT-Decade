// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract faucetNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;
    string private baseURI="";

    constructor() ERC721("faucetNFT", "FaucetNFT") {}

    function faucet() external {
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }
}
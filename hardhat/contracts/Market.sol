//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Market is ReentrancyGuard {

  event AskCreated(
    address indexed tokenContract,
    uint256 indexed tokenId,
    address indexed seller,
    uint256 price
  );

  event AskCanceled(
    address indexed tokenContract,
    uint256 indexed tokenId,
    address indexed seller,
    uint256 price
  );

  event AskFilled(
    address indexed tokenContract,
    uint256 indexed tokenId,
    address indexed buyer,
    address seller,
    uint256 price
  );

  struct Ask {
    address seller;
    uint256 price;
  }

  // Mapping of token address to mapping of token id to Ask
  mapping(address => mapping(uint256 => Ask)) public asks;
  

  function createAsk(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _price
  ) external nonReentrant {

    address tokenOwner = IERC721(_tokenContract).ownerOf(_tokenId);
    require(msg.sender == tokenOwner || IERC721(_tokenContract).isApprovedForAll(tokenOwner, msg.sender), "Only token owner or operator");

    asks[_tokenContract][_tokenId] = Ask(msg.sender, _price);

    emit AskCreated(_tokenContract, _tokenId, msg.sender, _price);

  }

  function cancelAsk(
    address _tokenContract,
    uint256 _tokenId
  ) external nonReentrant {
    
    Ask memory ask = asks[_tokenContract][_tokenId];

    address seller = ask.seller;

    require(msg.sender == seller || msg.sender == IERC721(_tokenContract).ownerOf(_tokenId), "Only token owner or operator");

    emit AskCanceled(_tokenContract, _tokenId, seller, ask.price);

    delete asks[_tokenContract][_tokenId];

  }

  function fillAsk(
    address _tokenContract,
    uint256 _tokenId
  ) external payable nonReentrant {

    Ask memory ask = asks[_tokenContract][_tokenId];

    address seller = ask.seller;

    require(seller != address(0), "Inactive ask");

    uint256 price = ask.price;

    require(msg.value == price, "Insufficient amount of ether");

    (bool success, ) = seller.call{value: msg.value}("");
    require(success, "Failed to transfer ether");

    IERC721(_tokenContract).transferFrom(seller, msg.sender, _tokenId);

    emit AskFilled(_tokenContract, _tokenId, msg.sender, seller, price);

    delete asks[_tokenContract][_tokenId];

  }

}

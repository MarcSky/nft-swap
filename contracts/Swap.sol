// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract NFTSwap {
    using Counters for Counters.Counter;

    Counters.Counter private _swapId;

    struct Swap {
        address from;
        address to;
        address contract1;
        address contract2;
        uint256 tokenId1;
        uint256 tokenId2;
    }

    mapping(uint256 => Swap) swaps;

    function createSwap(
        address to,
        address contract1,
        address contract2,
        uint256 tokenId1,
        uint256 tokenId2
    ) public returns (uint256){
        require(to != address(0x0), "to address cant be zero");
        require(contract1 != address(0x0), "contract1 address cant be zero");
        require(contract2 != address(0x0), "contract2 address cant be zero");
        require(IERC721(contract1).isApprovedForAll(msg.sender, address(this)), "createSwap: need approve your nft usage");

        _swapId.increment();
        uint256 swapId = _swapId.current();

        swaps[swapId] = Swap(
            msg.sender,
            to,
            contract1,
            contract2,
            tokenId1,
            tokenId2
        );

        return swapId;
    }

    function cancelSwap(uint256 swapId) public {
        require(swapId <= _swapId._value, "swapId less than maximum _swapId");
        require(swaps[swapId].from != address(0x0), "swap not exist");
        require(swaps[swapId].from == msg.sender, "cancel swap can make only owner");
        delete swaps[swapId];
    }

    function acceptSwap(uint256 swapId) public {
        require(swapId <= _swapId._value, "swapId less than maximum _swapId");

        Swap memory current = swaps[swapId];
        require(swaps[swapId].from != address(0x0), "swap not exist");
        require(current.to == msg.sender, "accept can make only second user");
        require(IERC721(current.contract2).isApprovedForAll(msg.sender, address(this)), "acceptSwap: need approve your nft usage");

        IERC721(current.contract1).safeTransferFrom(current.from, current.to, current.tokenId1);
        IERC721(current.contract2).safeTransferFrom(current.to, current.from, current.tokenId2);

        delete swaps[swapId];
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract NFTSwap2 {
    using Counters for Counters.Counter;

    Counters.Counter private _swapId;

    struct Swap {
        address user1;
        address user2;
        address contract1;
        address contract2;
        uint256 tokenId1;
        uint256 tokenId2;
        bool token1Received;
        bool token2Received;
    }

    mapping(uint256 => Swap) swaps;

    function createSwap(
        address user2,
        address contract1,
        address contract2,
        uint256 tokenId1,
        uint256 tokenId2
    ) public returns (uint256){
        require(user2 != address(0x0), "to address cant be zero");
        require(contract1 != address(0x0), "contract1 address cant be zero");
        require(contract2 != address(0x0), "contract2 address cant be zero");

        _swapId.increment();
        uint256 swapId = _swapId.current();

        swaps[swapId] = Swap(
            msg.sender,
            user2,
            contract1,
            contract2,
            tokenId1,
            tokenId2,
            false, false
        );

        return swapId;
    }

    function deposit(uint256 swapId, address contractAddress, uint256 tokenId) public {
        require(swapId <= _swapId._value, "swapId less than maximum _swapId");
        require(contractAddress != address(0x0), "contractAddress cant be zero");
        require(IERC721(contractAddress).isApprovedForAll(msg.sender, address(this)), "deposit: need approve your nft usage");

        Swap storage current = swaps[swapId];
        require(current.user1 != address(0x0), "swap not exist");

        if (current.user1 == msg.sender) {
            current.token1Received = true;
        } else if (current.user2 == msg.sender) {
            current.token2Received = true;
        }

        IERC721(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function cancelSwap(uint256 swapId) public {
        require(swapId <= _swapId._value, "swapId less than maximum _swapId");

        Swap memory current = swaps[swapId];
        require(current.user1 != address(0x0), "swap not exist");

        if (current.token1Received == true) {
            IERC721(current.contract1).safeTransferFrom(address(this), current.user1, current.tokenId1);
        }

        if (current.token2Received == true) {
            IERC721(current.contract2).safeTransferFrom(address(this), current.user2, current.tokenId2);
        }

        delete swaps[swapId];
    }

    function acceptSwap(uint256 swapId) public {
        require(swapId <= _swapId._value, "swapId less than maximum _swapId");

        Swap memory current = swaps[swapId];
        require(current.user1 != address(0x0), "swap not exist");
        require(current.token1Received && current.token2Received, "terms of the deal were not met");

        IERC721(current.contract1).safeTransferFrom(address(this), current.user2, current.tokenId1);
        IERC721(current.contract2).safeTransferFrom(address(this), current.user1, current.tokenId2);

        delete swaps[swapId];
    }
}
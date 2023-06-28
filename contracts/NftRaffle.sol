// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DeepLink.sol";

contract NftRaffle is IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    struct RaffleRound {
        uint256 ticketPrice;
        uint256 maxTickets;
        bool raffleEnded;
        uint256 winningTicketId;
        address winner;
        Counters.Counter ticketsSold;
        uint256 nftTokenId;
    }

    DeepLink private nftContract;
    Counters.Counter private currentRound;
    mapping(uint256 => RaffleRound) private raffleRounds;
    mapping(uint256 => mapping(uint256 => address)) private ticketToOwner;
    mapping(uint256 => uint256) private ticketsCount;

    event TicketPurchased(uint256 roundId, address indexed buyer, uint256 ticketId);
    event TicketClaimed(uint256 roundId, address indexed winner, uint256 ticketId);
    event WinnerSelected(uint256 roundId, address winner, uint256 ticketId);

    constructor(address _nftContract) {
        nftContract = DeepLink(_nftContract);
    }

    function createRaffleRound(uint256 _ticketPrice, uint256 _maxTickets) external onlyOwner {
        require(_ticketPrice > 0, "Ticket price must be greater than zero");
        require(_maxTickets > 0, "Max tickets must be greater than zero");

        uint256 _nftTokenId = nftContract.mintToken(address(this), "");

        RaffleRound memory round = RaffleRound({
            ticketPrice: _ticketPrice,
            maxTickets: _maxTickets,
            raffleEnded: false,
            winningTicketId: 0,
            winner: address(0),
            ticketsSold: Counters.Counter(1),
            nftTokenId: _nftTokenId
        });

        currentRound.increment();
        raffleRounds[currentRound.current()] = round;
    }

    function purchaseTicket(uint256 _roundId) external payable {
        RaffleRound storage round = raffleRounds[_roundId];
        require(!round.raffleEnded, "Raffle round ended");
        require(msg.value >= round.ticketPrice, "Insufficient payment");
        require(ticketsCount[_roundId] < round.maxTickets, "Maximum tickets per participant reached");

        uint256 ticketId = round.ticketsSold.current();
        round.ticketsSold.increment();
        ticketToOwner[_roundId][ticketId] = msg.sender;
        ticketsCount[_roundId]++;
        emit TicketPurchased(_roundId, msg.sender, ticketId);
    }

    function claimNft(uint256 _roundId, uint256 _ticketId) external {
        RaffleRound storage round = raffleRounds[_roundId];
        require(round.raffleEnded, "Raffle round not ended");
        require(ticketToOwner[_roundId][_ticketId] == msg.sender, "Ticket not owned by sender");
        require(nftContract.ownerOf(round.nftTokenId) == address(this), "NFT not in contract");

        // Check if the caller is the winner
        if (_ticketId == round.winningTicketId && msg.sender == round.winner) {
            // Caller is the winner, transfer the NFT
            nftContract.safeTransferFrom(address(this), msg.sender, _ticketId);
            ticketsCount[_roundId]--;
            emit TicketClaimed(_roundId, msg.sender, _ticketId);
        } else {
            // Caller is not the winner, throw an error or handle the situation accordingly
            revert("Only the winner can claim the NFT");
        }
    }

    function endRaffle(uint256 _roundId) external onlyOwner {
        RaffleRound storage round = raffleRounds[_roundId];
        require(!round.raffleEnded, "Raffle round already ended");
        require(round.maxTickets > 0, "No tickets sold in this round");

        round.raffleEnded = true;

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.basefee, round.maxTickets))
        ) % round.maxTickets;

        round.winningTicketId = randomNumber;
        round.winner = ticketToOwner[_roundId][randomNumber];
        emit WinnerSelected(_roundId, round.winner, round.winningTicketId);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner()).transfer(balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
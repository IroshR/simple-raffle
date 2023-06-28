import { expect } from "chai";
import { ethers } from "hardhat";
import { DeepLink, NftRaffle } from "../typechain-types";
  
describe("NftRaffle", function () {
    let nftRaffle: NftRaffle;
    let deepLink: DeepLink;
    let owner: any;
    let participant1: any;
    let participant2: any;
    let metadataURI: any;
  
    beforeEach(async function () {
        [owner, participant1, participant2] = await ethers.getSigners();
    
        const DeepLink = await ethers.getContractFactory("DeepLink");
        deepLink = await DeepLink.deploy();

        const NftRaffle = await ethers.getContractFactory("NftRaffle");
        nftRaffle = await NftRaffle.deploy(deepLink.getAddress());
        metadataURI = "https://example.com/metadata";
        
    
        await deepLink.mintToken(owner.address, metadataURI);
    });

    it("should allow participants to purchase tickets", async function () {
        const ticketPrice = 1;
        const maxTickets = 5;
    
        await nftRaffle.createRaffleRound(ticketPrice, maxTickets);
        
        // Purchase tickets for participant1
        await nftRaffle.connect(participant1).purchaseTicket(1, { value: ticketPrice });
        await nftRaffle.connect(participant1).purchaseTicket(1, { value: ticketPrice });
        await nftRaffle.connect(participant1).purchaseTicket(1, { value: ticketPrice });
    
        // Purchase tickets for participant2
        await nftRaffle.connect(participant2).purchaseTicket(1, { value: ticketPrice });
        await nftRaffle.connect(participant2).purchaseTicket(1, { value: ticketPrice });
    });
});
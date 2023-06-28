import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contrancts with the account: ${deployer.address}`);

  const provider = deployer.provider;
  const balance = await provider.getBalance(deployer.address);
  console.log(`Deploying Account balance: ${balance.toString()}`);

  const DeepLink = await ethers.getContractFactory('DeepLink');
  const deepLink = await DeepLink.deploy();
  console.log(`DeepLink NFT address: ${deepLink.getAddress()}`);

  const NftRaffle = await ethers.getContractFactory('NftRaffle');
  const nftRaffle = await NftRaffle.deploy(deepLink.getAddress());
  console.log(`Nft Raffle contract address: ${nftRaffle.getAddress()}`);

  console.log(`Done`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
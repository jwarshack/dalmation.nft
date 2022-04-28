const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Market", function () {

  let deployer
  let seller
  let buyer
  let market
  let nft

  beforeEach(async() => {
    [deployer, seller, buyer] = await ethers.getSigners()

    const Market = await ethers.getContractFactory("Market")
    market = await Market.deploy()

    const NFT = await ethers.getContractFactory("TestNFT", seller)
    nft = await NFT.deploy()

  })


  it("Should create ask", async function () {
    await market.connect(seller).createAsk(nft.address, 1, ethers.utils.parseEther('1'));

    const ask = await market.asks(nft.address, 1)
    expect(ask.seller).to.equal(seller.address)
    expect(ask.price).to.equal(ethers.utils.parseEther('1'))

  });

  it("Should fail to create ask if token doesn't exist", async function () {
    await expect(market.connect(seller).createAsk(nft.address, 2, ethers.utils.parseEther('1'))).to.be.revertedWith('ERC721: owner query for nonexistent token');
    
  });

  it("Should fail to create ask if token isn't owned", async function () {
    await expect(market.connect(buyer).createAsk(nft.address, 1, ethers.utils.parseEther('1'))).to.be.revertedWith('Only token owner or operator');
    
  });


  it("Should cancel ask", async function () {
    await market.connect(seller).cancelAsk(nft.address, 1);

    const ask = await market.asks(nft.address, 1)
    expect(ask.seller).to.equal(ethers.constants.AddressZero)
    expect(ask.price).to.equal(ethers.constants.Zero)
    
  });

  it("Should fill ask", async function () {
    await nft.connect(seller).setApprovalForAll(market.address, 1);

    await market.connect(seller).createAsk(nft.address, 1, ethers.utils.parseEther('1'));


    await market.connect(buyer).fillAsk(nft.address, 1, {value: ethers.utils.parseEther('1')});

    expect(await nft.ownerOf(1)).to.equal(buyer.address)
  });

  it("Should fail to fill ask if not enough ether passed in", async function () {
    await nft.connect(seller).setApprovalForAll(market.address, 1);

    await market.connect(seller).createAsk(nft.address, 1, ethers.utils.parseEther('1'));


    await expect(market.connect(buyer).fillAsk(nft.address, 1, {value: ethers.utils.parseEther('0.5')})).to.be.revertedWith('Insufficient amount of ether');

  });


});

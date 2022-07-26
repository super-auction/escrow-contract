const { expect } = require("chai");
const { ethers } = require("hardhat");
const { forwardTime, toEth, toWei } = require('./helper')

const dateHelper = (year, month, date) => {
  return +new Date(year, month-1, date) / 1000;
}

const log = console.log

describe("SuperEscrow", function () {
    let deployer, seller1, seller2, buyer1, buyer2;
    let escrowContract;

    const sell = async (user, url, priceInWei) => {
        await escrowContract.connect(user).sell(url, priceInWei);
    }

    const buy = async (user, id, priceInWei) => {
        const txOptions = { value: priceInWei }
        await escrowContract.connect(user).buy(id, txOptions)
    }

    const sendCode = async (user, id, code) => {
        await escrowContract.connect(user).sendCode(id, code)
    }

    const logDetails = async (id) => {
        const txDetails = await getDetails(id)
        log(JSON.stringify(txDetails))
    }

    const balance = async (user) => {
        const bal = await user.getBalance()
        log(`Balance of ${user.address}: ${toEth(bal)}`)
        return  bal;
    }

    const getUrl = async (user, id, passcode) => {
        const res = await escrowContract.connect(user).getUrl(id, passcode)
        return res;
    }

    const getDetails = async (txId) => {
        let details = await escrowContract.connect(deployer).getTxInfo(txId);
        const {
            id,
            url,
            buyer,
            seller,
            passcode,
            price,
            isPaid,
            isSentToSeller,
        } = {...details}

      return {
        id,
        url,
        buyer,
        seller,
        passcode,
        price,
        isPaid,
        isSentToSeller,
      }
    }

    beforeEach(async() => {
        [deployer, seller1, seller2, buyer1, buyer2] = await ethers.getSigners()
        const SuperEscrow = await ethers.getContractFactory("SuperEscrow");
        escrowContract = await SuperEscrow.deploy();
        await escrowContract.deployed();
    })

    it("Should process transaction", async function () {
        await sell(seller1, 'http://example.com/1', toWei('20'));
        await buy(buyer1, 1, toWei('20'));
        await balance(buyer1)

        await logDetails(1)

        await sendCode(seller1, 1, '1234')
        await logDetails(1)

        const res  = await getUrl(buyer1, 1, '1234')
        log(res)
        logDetails(1)
        
        try {
            await buy(buyer2, 1, toWei('20'));
        } catch (error) {
            
        }
        await balance(buyer2)
    }); 

});
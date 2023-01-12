from brownie import web3, accounts, config, escrowNFT, faucetNFT

def getAccount():
    account = accounts.from_mnemonic(config['wallets']['from_mnemonic'], count=3)
    return account[0], account[1], account[2]

def deployContract(owner):
    escrow = escrowNFT.deploy(2, {"from": owner})
    escrow.tx.wait(3)

    faucet = faucetNFT.deploy({"from":owner})
    faucet.tx.wait(3)

    return escrow, faucet

def main():
    developer, seller, buyer = getAccount()
    escrow, faucet = deployContract(developer)

    # Prepare simulation
    txFaucet = faucet.faucet({"from": seller})
    txFaucet.wait(3)

    txApprove = faucet.approve(escrow.address, 0, {"from": seller})
    txApprove.wait(3)

    # Simulation
    txId = escrow.generateTxId(seller.address, buyer.address, faucet.address, web3.keccak(text="test"))

    txCreate = escrow.createEscrow(txId, 0, web3.toWei("0.5", "ether"), faucet.address, buyer.address, {"from":seller})
    txCreate.wait(3)

    txPay = escrow.payEscrow(txId, {"from": buyer, "value": web3.toWei("0.5", "ether")})
    txPay.wait(3)

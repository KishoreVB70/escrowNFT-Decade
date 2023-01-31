from brownie import accounts, config, escrowNFT, faucetNFT, web3

def main():
    # Get the account to use
    account = accounts.from_mnemonic(config["wallets"]["from_mnemonic"], count=2)

    # Request Faucet
    txFaucet = faucetNFT[-1].faucet({"from": account[0]})
    txFaucet.wait(3)

    txApprove = faucetNFT[-1].approve(escrowNFT[-1].address, 0, {"from": account[0]})
    txApprove.wait(3)

    txId = escrowNFT[-1].generateTxId(account[0], account[1], faucetNFT[-1].address, web3.keccak(text="test"), {"from": account[0]})

    txCreate = escrowNFT[-1].createEscrow(txId, 0, web3.toWei("0.5", "ether"), faucetNFT[-1].address, account[1], {"from": account[0]})
    txCreate.wait(3)

    txPay = escrowNFT[-1].payEscrow(txId, {"from": account[1], "value": web3.toWei("0.5", "ether")})
    txPay.wait(3)

    balance = faucetNFT[-1].balanceOf(account[1])
    print(balance)
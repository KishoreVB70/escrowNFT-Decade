from brownie import accounts, config, escrowNFT, faucetNFT

def main():
    # Get the account to use
    account = accounts.from_mnemonic(config["wallets"]["from_mnemonic"])

    # Deploy the contract
    contract = escrowNFT.deploy(2, {"from": account})
    faucets = faucetNFT.deploy({"from": account})
    faucets.tx.wait(3)

    # Wait for the transaction to be mined
    contract.tx.wait(3)

    print("Contract deployed to:", contract.address)
    print("Faucet deployed to:", faucets.address)
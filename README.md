# Setup

npm install

# To deploy in Avalanche

Create a .secret file with your mnemonic. Then run:

    truffle migrate --reset --compile-all --network avax

On the Strategy Contract execute:

    doApprovals()

On the Vault Contract execute:

    setStrategy(<STRATEGY_ADDRESS>)

Your ready to deposit funds via the Vault Contract with

    deposit(<AMOUNT>)
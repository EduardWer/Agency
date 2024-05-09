
from web3 import  Web3

w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:7545"))
accounts = w3.eth.accounts

# Перебираем все аккаунты и получаем их балансы
for account in accounts:
    balance = w3.eth.get_balance(account)
    balance_in_ether = w3.from_wei(balance, 'ether')
    print(f"Баланс аккаунта {account}: {balance_in_ether} ETH")

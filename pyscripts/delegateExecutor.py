import sha3
from web3 import Web3
from eth_account import Account
from eth_account.signers.local import LocalAccount
from web3 import Web3, EthereumTesterProvider
from web3.middleware import construct_sign_and_send_raw_middleware

address = "0x0000000000000000000000000000000000000000"
network = "XDC"
amount = 0
sendTo = "BLANK"
tokenID = [0]


private_key = "this is suposed to be a word key"



class NetworkTXNs()

    init():
        w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))


    def Send():
        print("send %s %s to %s", (amount,network,sendTo))
        #web3.eth.send_transaction(sendTo,,amount)

    def SendXRC20():
        print("sendXRC20 %s %s to %s", (amount,network,sendTo))

    def SendXRC1155():
        print("sendXRC1155 %s %s to %s", (amount,network,sendTo))

    def ExecuteContract():
        print("sendXRC1155 %s %s to %s", (amount,network,sendTo))

if __name__ == "__main__" :
    print("start program")
    password = input("Enter a password: ")


    k = sha3.keccak_256()
    data = 'age'.encode('utf-8')  # Encode the string 'age' into bytes
    k.update(data)
    #print(k.hexdigest())

    enter = input("Enter a value: ")
    
    if enter == "1":
        Send()
    elif enter == "2":
        SendXRC20()
    elif enter == "3":
        SendXRC1155()
    else:
        print("Error")
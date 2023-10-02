import sha3
from web3 import Web3, AsyncWeb3

class executeWeb3:
    w3 = None
    network = None
    userAddress = None

    def __init__(self,network,userAddress):
        self.network = network
        self.userAddress = userAddress

        print("Joining: [ %s ] network, with Address: %s" % (self.network,self.userAddress ))

        w3 = Web3(Web3.HTTPProvider(self.network))
        self.w3 = w3
        print(self.w3.is_connected())
        self.balance(userAddress)

    def balance(self,address):
        balance = self.w3.eth.get_balance(address)
        print(balance)
        return balance

    def send(amount,network,sendTo):
        w3.send(self)
        print("send %s %s to %s", (amount,network,sendTo))
        #web3.eth.send_transaction(sendTo,,amount)

    def sendXRC20(self,amount,address,sendTo):
        abi = ""
        contract = w3.eth.contract(address=address, abi=abi)


        print("sendXRC20 %s %s to %s", (amount,network,sendTo))

    def sendXRC1155(self,amount,address,sendTo):
        abi = ""
        contract = w3.eth.contract(address=address, abi=abi)


        print("sendXRC1155 %s %s to %s", (amount,network,sendTo))

    def setPrivateKey(self,seed):
        print("set private key")

    def retrivePrivateKey():
        print("set private key")

    def call(self,url):
        address, abi = getCIML(url)
        contract = w3.eth.contract(address=address, abi=abi)

        ##contract calls

        print("call Address: %s ABI: %s to %s", (address,abi))

    def getCIML(self,url):
        #S3 get url
        #parse json data for 
        address = ""
        abi = ""
        return address, abi

class parseJSON:

    json = None
    def __init__(_json):
        json = _json

    

if __name__ == "__main__" :
    address = "0xD69B4e5e5A7D5913Ca2d462810592fcd22F6E003"

    print("start program from: %s" % address)

    k = sha3.keccak_256()
    data = 'age'.encode('utf-8')  
    k.update(data)
    #print(k.hexdigest())

    exe = executeWeb3("http://127.0.0.1:8545",address)

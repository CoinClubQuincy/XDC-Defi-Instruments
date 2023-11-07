import sha3
from web3.auto import w3
from web3 import Web3
from web3 import Web3, EthereumTesterProvider
from web3.middleware import construct_sign_and_send_raw_middleware
from eth_account import Account
import os

class LocalSeedStorageTest:
    users = []
    def create_user(self, address, seed, index):
        existing_user = next((user for user in self.users if user["address"] == address), None)
        if existing_user:
            self.users.remove(existing_user)

        user = {
            "address": address,
            "seed": seed,
            "index": index,
        }

        self.users.append(user)
        return 

class executeWeb3:
    erc20_contract_abi = [
    {"constant": True,"inputs": [],"name": "name","outputs": [{"name": "", "type": "string"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [],"name": "symbol","outputs": [{"name": "", "type": "string"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [],"name": "decimals","outputs": [{"name": "", "type": "uint8"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_spender", "type": "address"}, {"name": "_value", "type": "uint256"}],"name": "approve","outputs": [{"name": "success", "type": "bool"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_owner", "type": "address"}, {"name": "_spender", "type": "address"}],"name": "allowance","outputs": [{"name": "remaining", "type": "uint256"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_to", "type": "address"}, {"name": "_value", "type": "uint256"}],"name": "transfer","outputs": [{"name": "success", "type": "bool"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_spender", "type": "address"}, {"name": "_value", "type": "uint256"}, {"name": "_extraData", "type": "bytes"}],"name": "approveAndCall","outputs": [{"name": "success", "type": "bool"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_owner", "type": "address"}],"name": "balanceOf","outputs": [{"name": "balance", "type": "uint256"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_from", "type": "address"}, {"name": "_to", "type": "address"}, {"name": "_value", "type": "uint256"}],"name": "transferFrom","outputs": [{"name": "success", "type": "bool"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_to", "type": "address"}, {"name": "_value", "type": "uint256"}, {"name": "_extraData", "type": "bytes"}],"name": "transferAndCall","outputs": [{"name": "success", "type": "bool"}],"payable": False,"type": "function"},
    {"inputs": [{"name": "_initialAmount", "type": "uint256"}, {"name": "_tokenName", "type": "string"}, {"name": "_decimalUnits", "type": "uint8"}, {"name": "_tokenSymbol", "type": "string"}],"type": "constructor"},
    {"anonymous": False,"inputs": [{"indexed": True, "name": "_from", "type": "address"}, {"indexed": True, "name": "_to", "type": "address"}, {"indexed": False, "name": "_value", "type": "uint256"}],"name": "Transfer","type": "event"},
    {"anonymous": False,"inputs": [{"indexed": True, "name": "_owner", "type": "address"}, {"indexed": True, "name": "_spender", "type": "address"}, {"indexed": False, "name": "_value", "type": "uint256"}],"name": "Approval","type": "event"}
    ]
    erc1155_contract_abi = [
    {"constant": True,"inputs": [{"name": "account","type": "address"},{"name": "id","type": "uint256"}],"name": "balanceOf","outputs": [{"name": "","type": "uint256"}],"payable": False,"stateMutability": "view","type": "function"},
	{"inputs": [{"internalType": "address","name": "from","type": "address"},{"internalType": "address","name": "to","type": "address"},{"internalType": "uint256[]","name": "ids","type": "uint256[]"},{"internalType": "uint256[]","name": "values","type": "uint256[]"},{"internalType": "bytes","name": "data","type": "bytes"}],"name": "safeBatchTransferFrom","outputs": [],"stateMutability": "nonpayable","type": "function"},
    {"constant": True,"inputs": [{"name": "owner","type": "address"}],"name": "isApprovedForAll","outputs": [{"name": "","type": "bool"}],"payable": False,"stateMutability": "view","type": "function"},
    {"constant": False,"inputs": [{"name": "operator","type": "address"},{"name": "approved","type": "bool"}],"name": "setApprovalForAll","outputs": [],"payable": False,"stateMutability": "nonpayable","type": "function"},
    {"anonymous": False,"inputs": [{"indexed": True,"name": "operator","type": "address"},{"indexed": True,"name": "from","type": "address"},{"indexed": True,"name": "to","type": "address"},{"indexed": False,"name": "id","type": "uint256"},{"indexed": False,"name": "amount","type": "uint256"}],"name": "TransferSingle","type": "event"},
    {"anonymous": False,"inputs": [{"indexed": True,"name": "operator","type": "address"},{"indexed": True,"name": "from","type": "address"},{"indexed": True,"name": "to","type": "address"},{"indexed": False,"name": "ids","type": "uint256[]"},{"indexed": False,"name": "amounts","type": "uint256[]"}],"name": "TransferBatch","type": "event"},
    {"anonymous": False,"inputs": [{"indexed": True,"name": "owner","type": "address"},{"indexed": True,"name": "operator","type": "address"},{"indexed": False,"name": "approved","type": "bool"}],"name": "ApprovalForAll","type": "event"}
    ]
    erc721_contract_abi = [
    {"constant": True,"inputs": [],"name": "name","outputs": [{"name": "","type": "string"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [],"name": "symbol","outputs": [{"name": "","type": "string"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_tokenId","type": "uint256"}],"name": "ownerOf","outputs": [{"name": "owner","type": "address"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_tokenId","type": "uint256"}],"name": "exists","outputs": [{"name": "","type": "bool"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_owner","type": "address"}],"name": "balanceOf","outputs": [{"name": "balance","type": "uint256"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_to","type": "address"},{"name": "_tokenId","type": "uint256"}],"name": "transferFrom","outputs": [],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_to","type": "address"},{"name": "_tokenId","type": "uint256"},{"name": "_data","type": "bytes"}],"name": "safeTransferFrom","outputs": [],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_to","type": "address"},{"name": "_tokenId","type": "uint256"},{"name": "_data","type": "bytes"},{"name": "_operator","type": "address"}],"name": "safeTransferFrom","outputs": [],"payable": False,"type": "function"},
    {"constant": True,"inputs": [],"name": "totalSupply","outputs": [{"name": "","type": "uint256"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_owner","type": "address"},{"name": "_index","type": "uint256"}],"name": "tokenOfOwnerByIndex","outputs": [{"name": "","type": "uint256"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_index","type": "uint256"}],"name": "tokenByIndex","outputs": [{"name": "","type": "uint256"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_to","type": "address"},{"name": "_tokenId","type": "uint256"}],"name": "approve","outputs": [],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_tokenId","type": "uint256"}],"name": "getApproved","outputs": [{"name": "operator","type": "address"}],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_tokenId","type": "uint256"}],"name": "isApprovedForAll","outputs": [{"name": "approved","type": "bool"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_operator","type": "address"},{"name": "_approved","type": "bool"}],"name": "setApprovalForAll","outputs": [],"payable": False,"type": "function"},
    {"constant": True,"inputs": [{"name": "_tokenId","type": "uint256"}],"name": "tokenURI","outputs": [{"name": "","type": "string"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [],"name": "supportsInterface","outputs": [{"name": "","type": "bool"}],"payable": False,"type": "function"},
    {"constant": False,"inputs": [{"name": "_from","type": "address"},{"name": "_to","type": "address"},{"name": "_tokenId","type": "uint256"},{"name": "_data","type": "bytes"}],"name": "safeTransferFrom","outputs": [],"payable": False,"type": "function"},
    {"inputs": [{"name": "_name","type": "string"},{"name": "_symbol","type": "string"}],"type": "constructor"},
    {"anonymous": False,"inputs": [{"indexed": True,"name": "_from","type": "address"},{"indexed": True,"name": "_to","type": "address"},{"indexed": True,"name": "_tokenId","type": "uint256"}],"name": "Transfer","type": "event"},
    {"anonymous": False,"inputs": [{"indexed": True,"name": "_owner","type": "address"},{"indexed": True,"name": "_approved","type": "address"},{"indexed": True,"name": "_tokenId","type": "uint256"}],"name": "Approval","type": "event"},
    {"anonymous": False,"inputs": [{"indexed": True,"name": "_owner","type": "address"},{"indexed": True,"name": "_operator","type": "address"},{"indexed": False,"name": "_approved","type": "bool"}],"name": "ApprovalForAll","type": "event"}
    ]

    def __init__(self,_network,_sender_address):
        network = _network
        sender_address = _sender_address

        self.w3 = Web3(Web3.HTTPProvider(network))
        Account.enable_unaudited_hdwallet_features()
        print("Joining: [ %s ] network, with Address: %s IS CONNECTED %s" % (network,sender_address,self.w3.is_connected()))


    def balance(self,address):
        balance = self.w3.eth.get_balance(address)
        return balance

    def _formatToFloat(self,number):
        formatted_number = number / 1000000000000000000
        return formatted_number

    def _formatToBigInt(self,number):
        formatted_number = number * 1000000000000000000
        return formatted_number

    def seed_to_private_key(self,seed):
        account = Account.from_mnemonic(seed)
        private_key_hex = account.key.hex()
        return private_key_hex

    def send(self,amount,sendTo,privateKey):
        userSelf = self.w3.eth.account.from_key(privateKey)

        self.w3.middleware_onion.add(construct_sign_and_send_raw_middleware(userSelf))
     
        transaction = {
            "from": userSelf.address,
            "to": sendTo,
            "value": amount,
            "gas": 21000, 
            "gasPrice": 25,
        }

        tx_hash = self.w3.eth.send_transaction(transaction)

        tx = w3.eth.get_transaction(tx_hash)
        return tx_hash

    def sendXRC20(self, erc20_contract_address, amount, receiver_address, private_key):
        erc20_contract = self.w3.eth.contract(address=erc20_contract_address, abi=self.erc20_contract_abi)
        sender_address = self.w3.eth.account.from_key(private_key).address

        transaction = erc20_contract.functions.transfer(receiver_address, amount)

        signed_transaction = self.w3.eth.account.sign_transaction(
            transaction.build_transaction({
                "gas": 200000,
                "gasPrice": 25,  
                "nonce": self.w3.eth.get_transaction_count(sender_address),
            }),
            private_key=private_key,
        )
        tx_hash = self.w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
        #self.w3.eth.wait_for_transaction_receipt(tx_hash)

        return tx_hash


    def balanceXRC20(self, erc20_contract_address, address_to_check):
        erc20_contract = self.w3.eth.contract(address=w3.to_checksum_address(erc20_contract_address), abi=self.erc20_contract_abi)
        symbol = erc20_contract.functions.symbol().call()
        decimals = erc20_contract.functions.decimals().call()
        name = erc20_contract.functions.name().call()
        #totalSupply = erc20_contract.functions.totalSupply().call() / 10**decimals

        balance = erc20_contract.functions.balanceOf(address_to_check).call() / 10**decimals
        return (name,symbol,balance,decimals)


    def sendERC1155(self, erc1155_contract_address, token_id, amount, receiver_address, private_key):
        erc1155_contract = self.w3.eth.contract(address=erc1155_contract_address, abi=self.erc1155_contract_abi)
        sender_address = self.w3.eth.account.from_key(private_key).address
        transaction = erc1155_contract.functions.safeBatchTransferFrom(sender_address, receiver_address, token_id, amount, b"")

        transaction_dict = {
            "gas": 200000,
            "gasPrice": 25,
            "nonce": self.w3.eth.get_transaction_count(sender_address)
        }

        signed_transaction = self.w3.eth.account.sign_transaction(
            transaction.build_transaction(transaction_dict),
            private_key=private_key,
        )
        
        tx_hash = self.w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
        self.w3.eth.wait_for_transaction_receipt(tx_hash)
        return tx_hash


    def balanceERC1155(self, contract_address, address_to_check, token_id):
        erc1155_contract = self.w3.eth.contract(address=contract_address, abi=self.erc1155_contract_abi)
        balance = erc1155_contract.functions.balanceOf(address_to_check, token_id).call()
        return balance

    def sendERC721(self, erc721_contract_address, token_id, receiver_address, private_key):
        erc721_contract = self.w3.eth.contract(address=erc721_contract_address, abi=self.erc721_contract_abi)
        sender_address = self.w3.eth.account.from_key(private_key).address

        transaction = erc721_contract.functions.safeTransferFrom(sender_address, receiver_address, token_id)
        
        nonce = self.w3.eth.get_transaction_count(sender_address)
        gas_price = self.w3.toWei(25, "gwei")
        gas_limit = 200000

        transaction_dict = {
            "gas": gas_limit,
            "gasPrice": gas_price,
            "nonce": nonce,
            "chainId": self.chain_id
        }

        signed_transaction = self.w3.eth.account.sign_transaction(
            transaction.buildTransaction(transaction_dict),
            private_key=private_key,
        )
        
        tx_hash = self.w3.eth.send_raw_transaction(signed_transaction.rawTransaction)
        self.w3.eth.wait_for_transaction_receipt(tx_hash)

        return tx_hash

    def balanceERC721(self, erc721_contract_address, token_id, address_to_check):
        erc721_contract = self.w3.eth.contract(address=erc721_contract_address, abi=self.erc721_contract_abi)
        balance = erc721_contract.functions.balanceOf(address_to_check, token_id).call()
        return balance

    def call_contract_function(self, contract_address, contract_abi, function_name, function_params, sender_private_key):
        contract = self.w3.eth.contract(address=contract_address, abi=contract_abi)
        key = self.w3.eth.account.from_key(sender_private_key)

        if function_name not in contract.functions:
            raise ValueError(f"Function '{function_name}' not found in contract ABI")

        contract_function = getattr(contract.functions, function_name)
        result = contract_function(*function_params).call()
        
        #result = contract_function(*function_params).call()
        #self.w3.eth.wait_for_transaction_receipt(transaction_hash)
        
        return result

    def transaction_hash(self,txn):
        transaction = self.w3.eth.get_transaction(txn)
        if transaction is None:
            print(f"Transaction {transaction_hash} not found.")
            return "no transaction found"
        else:
            return transaction

class parseJSON:
    def parse_objects(self,json_objects):
        views = []
        sends = []
        contracts = []

        for obj in json_objects:
            obj_type = obj.get("type")
            obj_call = obj.get("call")

            if obj_type == "Read":
                address = obj_call.get("address", "")
                tokens = obj_call.get("tokens", [])
                nft = obj_call.get("nft", [])
                views.append({"address": address, "tokens": tokens, "nft": nft})

            elif obj_type == "Transfer":
                asset = obj_call.get("asset", "")
                send_to = obj_call.get("send_to", "")
                amount = obj_call.get("amount", [])
                id_list = obj_call.get("id", [])
                sends.append({"asset": asset, "send_to": send_to, "amount": amount, "id": id_list})

            elif obj_type == "Write":
                address = obj_call.get("address", "")
                abi = obj_call.get("abi", "")
                function = obj_call.get("function", "")
                call_list = obj_call.get("call", [])
                contracts.append({"address": address,"abi": abi,"function": function, "call": call_list})

        return views, sends, contracts

    def get_network_details(network, networks_list):
        for network_info in networks_list:
            if network_info.get("network") == network:
                return network_info.get("symbol"), network_info.get("rpc")
        return None, None

    def read_file(filename):
        with open(filename, "r") as file:
            file_content = file.read()
            return file_content

class executeAPI:
    exe = None
    erc20_contract_abi = None
    erc1155_contract_abi = None

    def __init__(self,address,network):
        self.exe = executeWeb3(network,address)
        self.erc20_contract_abi = self.exe.erc20_contract_abi
        self.erc1155_contract_abi = self.exe.erc1155_contract_abi
        
    def executeView(self,views,network):
        address = views["address"]
        tokens = views["tokens"]
        NFTs = views["nft"]

        comma = ""
        if len(tokens) != 0:
            comma = ","
        token_details_list = []

        try:
            for i in tokens:
                try:
                    name, symbol, balance, decimals = self.exe.balanceXRC20(i, address)
                    
                    token_details = {
                        "asset": name,
                        "amount": balance,
                        "address": i
                    }
                    
                    token_details_list.append(token_details)

                except Exception as e:
                    token_details = {
                        "asset": "error ERC20",
                        "amount": "0",
                        "address": i
                    }
                    token_details_list.append(token_details)
            
            for t in NFTs:
                    for item in t["id"]:
                        try:
                            error = "default error"
                            if(self.is_erc1155_contract(t["contract"] ) == True):
                                error = "Error ERC1155"
                                balance = self.exe.balanceERC1155(t["contract"], address,item)

                            if(self.is_erc721_contract(t["contract"]) == True):
                                error = "Error ERC721"
                                balance = self.exe.balanceERC721(t["contract"], address,item)

                            token_details = {
                                "asset": item,
                                "amount": balance,
                                "address": t["contract"] 
                            }
                            token_details_list.append(token_details)

                        except Exception as e:
                            token_details = {
                                "asset": item,
                                "amount": error,
                                "address": t["contract"]
                            }
                            token_details_list.append(token_details)


            jsonObj = """     {
                "type":"Read",
                "return":{
                    "balanceOf": [
                        {
                        "asset": "%s",
                        "amount": %s,
                        "address": "%s"
                        }%s
                        %s
                    ],
                    "output": [200]
                }
            }
            """ % (network,self.exe.balance(address),address,comma,token_details_list)
            
        except Exception as e:
            jsonObj = """     {
                    "type":"View",
                    "return":{
                        "output": [500]
                    }
                }
                """ 

        return jsonObj

    def executeSend(self,sends,privateKey):
        asset = sends["asset"]
        send_to = sends["send_to"]
        amount = sends["amount"]
        ids = sends["id"]

        token_details_list = []
        try:
            if(asset == "0x0000000000000000000000000000000000000000"):
                txhash = self.exe.send(amount[0],send_to,privateKey)
                token_details = {
                    "txn_hash": txhash.hex(),
                    "amount": amount[0],
                    "asset": "native"
                }
                token_details_list.append(token_details)    

            elif(asset != "0x0000000000000000000000000000000000000000" and self.is_erc1155_contract(asset) != True and self.is_erc721_contract(asset) != True ):
                txhash = self.exe.sendXRC20(asset,amount[0],send_to,privateKey)
                token_details = {
                    "txn_hash": txhash.hex(),
                    "amount": amount[0],
                    "asset": asset
                }
                token_details_list.append(token_details)  

            elif(self.is_erc1155_contract(asset) == True):
                txhash = self.exe.sendERC1155(asset, ids, amount, send_to, privateKey)
                token_details = {
                    "txn_hash": txhash.hex(),
                    "amount": amount,
                    "asset": asset
                }
                token_details_list.append(token_details)  

            elif(self.is_erc721_contract(asset) == True):
                # txhash = self.exe.sendXRC721(asset[0], ids[0], amount, send_to, privateKey)
                print("trigger XRC721send")
                token_details = {
                    "txn_hash": txhash.hex(),
                    "amount": amount[0],
                    "asset": asset
                }
                token_details_list.append(token_details) 

        except Exception as e:
            token_details = {
                "txn_hash": "general Transfer error",
                "amount": amount,
                "asset": asset
            }
            token_details_list.append(token_details)  

        jsonObj = """     {
            "type":"Transfer",
            "return":{
                "Transfer": %s,
                "output": [200]
            }
        }
        """ % (token_details_list)

        return jsonObj

    def executeContracts(self,contracts,privateKey):
        contract_address = contracts["address"]
        contract_abi = contracts["abi"]
        function = contracts["function"]
        call = contracts["call"]

        try:
            output = self.exe.call_contract_function( contract_address, contract_abi, function, call,privateKey)
            token_details = {
                "output": output,
                "function": function,
                "contract": contract_address
            }
  
        except Exception as e:
            token_details = {
                "output": "error",
                 "function": function,
                "contract": contract_address
            }

        jsonObj = """     {
            "type":"Write",
            "return": %s 
        }
        """ % token_details
        
        return jsonObj

    def is_erc20_contract(self,address):
        try:
            contract = self.exe.w3.eth.contract(address=address, abi=self.erc20_contract_abi)
            totalSupply = contract.functions.decimals()
            return True
        except:
            return False

    def is_erc1155_contract(self,address):
        try:
            contract = self.exe.w3.eth.contract(address=address, abi=self.erc1155_contract_abi)
            contract.functions.balanceOf(address, 0).call()
            return True
        except:
            return False

    def is_erc721_contract(self,address):
        try:
            contract = self.exe.w3.eth.contract(address=address, abi=[self.erc721_contract_abi])
            return hasattr(contract.functions, "balanceOf") and "Transfer" in contract.events
        except:
            return False


import sha3
from web3.auto import w3
from web3 import Web3, AsyncWeb3
from web3 import Web3, EthereumTesterProvider
from web3.middleware import construct_sign_and_send_raw_middleware
from eth_account import Account
import os
import boto3

class executeWeb3:
    w3 = None
    sender_address = None
    erc20_contract_abi = [
    {
        'constant': True,
        'inputs': [],
        'name': 'name',
        'outputs': [{'name': '', 'type': 'string'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': True,
        'inputs': [],
        'name': 'symbol',
        'outputs': [{'name': '', 'type': 'string'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': True,
        'inputs': [],
        'name': 'decimals',
        'outputs': [{'name': '', 'type': 'uint8'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': False,
        'inputs': [{'name': '_spender', 'type': 'address'}, {'name': '_value', 'type': 'uint256'}],
        'name': 'approve',
        'outputs': [{'name': 'success', 'type': 'bool'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': True,
        'inputs': [{'name': '_owner', 'type': 'address'}, {'name': '_spender', 'type': 'address'}],
        'name': 'allowance',
        'outputs': [{'name': 'remaining', 'type': 'uint256'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': False,
        'inputs': [{'name': '_to', 'type': 'address'}, {'name': '_value', 'type': 'uint256'}],
        'name': 'transfer',
        'outputs': [{'name': 'success', 'type': 'bool'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': False,
        'inputs': [{'name': '_spender', 'type': 'address'}, {'name': '_value', 'type': 'uint256'}, {'name': '_extraData', 'type': 'bytes'}],
        'name': 'approveAndCall',
        'outputs': [{'name': 'success', 'type': 'bool'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': True,
        'inputs': [{'name': '_owner', 'type': 'address'}],
        'name': 'balanceOf',
        'outputs': [{'name': 'balance', 'type': 'uint256'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': False,
        'inputs': [{'name': '_from', 'type': 'address'}, {'name': '_to', 'type': 'address'}, {'name': '_value', 'type': 'uint256'}],
        'name': 'transferFrom',
        'outputs': [{'name': 'success', 'type': 'bool'}],
        'payable': False,
        'type': 'function'
    },
    {
        'constant': False,
        'inputs': [{'name': '_to', 'type': 'address'}, {'name': '_value', 'type': 'uint256'}, {'name': '_extraData', 'type': 'bytes'}],
        'name': 'transferAndCall',
        'outputs': [{'name': 'success', 'type': 'bool'}],
        'payable': False,
        'type': 'function'
    },
    {
        'inputs': [{'name': '_initialAmount', 'type': 'uint256'}, {'name': '_tokenName', 'type': 'string'}, {'name': '_decimalUnits', 'type': 'uint8'}, {'name': '_tokenSymbol', 'type': 'string'}],
        'type': 'constructor'
    },
    {
        'anonymous': False,
        'inputs': [{'indexed': True, 'name': '_from', 'type': 'address'}, {'indexed': True, 'name': '_to', 'type': 'address'}, {'indexed': False, 'name': '_value', 'type': 'uint256'}],
        'name': 'Transfer',
        'type': 'event'
    },
    {
        'anonymous': False,
        'inputs': [{'indexed': True, 'name': '_owner', 'type': 'address'}, {'indexed': True, 'name': '_spender', 'type': 'address'}, {'indexed': False, 'name': '_value', 'type': 'uint256'}],
        'name': 'Approval',
        'type': 'event'
    }
]
    erc1155_contract_abi = [
    {
        "constant": True,
        "inputs": [
            {
                "name": "account",
                "type": "address"
            },
            {
                "name": "id",
                "type": "uint256"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "name": "",
                "type": "uint256"
            }
        ],
        "payable": False,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": False,
        "inputs": [
            {
                "name": "to",
                "type": "address"
            },
            {
                "name": "id",
                "type": "uint256"
            },
            {
                "name": "amount",
                "type": "uint256"
            },
            {
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "payable": False,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": True,
        "inputs": [
            {
                "name": "owner",
                "type": "address"
            }
        ],
        "name": "isApprovedForAll",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": False,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": False,
        "inputs": [
            {
                "name": "operator",
                "type": "address"
            },
            {
                "name": "approved",
                "type": "bool"
            }
        ],
        "name": "setApprovalForAll",
        "outputs": [],
        "payable": False,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": True,
                "name": "operator",
                "type": "address"
            },
            {
                "indexed": True,
                "name": "from",
                "type": "address"
            },
            {
                "indexed": True,
                "name": "to",
                "type": "address"
            },
            {
                "indexed": False,
                "name": "id",
                "type": "uint256"
            },
            {
                "indexed": False,
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "TransferSingle",
        "type": "event"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": True,
                "name": "operator",
                "type": "address"
            },
            {
                "indexed": True,
                "name": "from",
                "type": "address"
            },
            {
                "indexed": True,
                "name": "to",
                "type": "address"
            },
            {
                "indexed": False,
                "name": "ids",
                "type": "uint256[]"
            },
            {
                "indexed": False,
                "name": "amounts",
                "type": "uint256[]"
            }
        ],
        "name": "TransferBatch",
        "type": "event"
    },
    {
        "anonymous": False,
        "inputs": [
            {
                "indexed": True,
                "name": "owner",
                "type": "address"
            },
            {
                "indexed": True,
                "name": "operator",
                "type": "address"
            },
            {
                "indexed": False,
                "name": "approved",
                "type": "bool"
            }
        ],
        "name": "ApprovalForAll",
        "type": "event"
    }
]

    def __init__(self,_network,_sender_address):
        network = _network
        sender_address = _sender_address

        print("Joining: [ %s ] network, with Address: %s" % (network,sender_address))

        w3 = Web3(Web3.HTTPProvider(network))
        Account.enable_unaudited_hdwallet_features()

        self.w3 = w3
        print(self.w3.is_connected())
        self.balance(sender_address)

    def balance(self,address):
        balance = self.w3.eth.get_balance(address)
        print(self._formatToFloat(balance))
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
            "gas": 21000,  # You can adjust this based on your transaction needs
            "gasPrice": 25,
        }

        tx_hash = self.w3.eth.send_transaction(transaction)

        tx = w3.eth.get_transaction(tx_hash)
        print(tx)
        print("Balance: %s" % self.balance(userSelf.address))

    def sendXRC20(self,erc20_contract_address,amount,receiver_address,private_key):
        erc20_contract = w3.eth.contract(address=erc20_contract_address, abi=self.erc20_contract_abi)

        transaction = erc20_contract.functions.transfer(receiver_address, amount).buildTransaction({
            'gas': 200000,  # Adjust the gas limit as needed
            'gasPrice': 25,  # Adjust the gas price as needed
            'nonce': w3.eth.getTransactionCount(sender_address),
        })

        signed_transaction = w3.eth.account.signTransaction(transaction, private_key=private_key)

        transaction_hash = w3.eth.sendRawTransaction(signed_transaction.rawTransaction)
        print(f"Transaction Hash: {transaction_hash.hex()}")

        # Wait for the transaction to be mined
        #transaction_receipt = w3.eth.waitForTransactionReceipt(transaction_hash)
        print(f"Transaction Status: {transaction_receipt['status']}")
        return transaction_hash

    def balanceXRC20(self, erc20_contract_address, address_to_check):
        erc20_contract = self.w3.eth.contract(address=w3.to_checksum_address(erc20_contract_address), abi=self.erc20_contract_abi)
        symbol = erc20_contract.functions.symbol().call()
        decimals = erc20_contract.functions.decimals().call()
        #totalSupply = erc20_contract.functions.totalSupply().call() / 10**decimals

        balance = erc20_contract.functions.balanceOf(address_to_check).call() / 10**decimals
        print(f"Balance of {address_to_check}: {balance}")
        return balance

    def sendXRC1155(self, contract_address, token_id, amount, receiver_address, private_key):
        erc1155_contract = self.w3.eth.contract(address=contract_address, abi=self.erc1155_contract_abi)

        # Create a transaction to send tokens
        transaction = erc1155_contract.functions.safeTransferFrom(
            self.sender_address, receiver_address, token_id, amount, b"").buildTransaction({
                'gas': 200000, 
                'gasPrice': 25,  
                'nonce': self.w3.eth.getTransactionCount(self.sender_address),
            })

        signed_transaction = self.w3.eth.account.signTransaction(transaction, private_key=private_key)

        transaction_hash = self.w3.eth.sendRawTransaction(signed_transaction.rawTransaction)
        print(f"Transaction Hash: {transaction_hash.hex()}")

        #receipt = self.w3.eth.waitForTransactionReceipt(transaction_hash)
        print(f"Transaction Status: {receipt['status']}")

    def balanceXRC1155(self, contract_address, address_to_check, token_id):
        erc1155_contract = self.w3.eth.contract(address=contract_address, abi=self.erc1155_contract_abi)

        # Get the balance for the given address and token ID
        balance = erc1155_contract.functions.balanceOf(address_to_check, token_id).call()
        print(f"Balance of Token ID {token_id} for {address_to_check}: {balance}")
        return balance

#####################################
    def call_contract_function(url,function_name, function_params,seed):
        # Create a contract instance
        aws = AWS()
        contract_address, contract_abi = aws.getCIML(url)
        contract = self.w3.eth.contract(address=contract_address, abi=contract_abi)

        # Get the function object dynamically by name
        if function_name not in contract.functions:
            raise ValueError(f"Function '{function_name}' not found in contract ABI")

        contract_function = getattr(contract.functions, function_name)

        # Build the transaction
        transaction = contract_function(*function_params).buildTransaction({
            'chainId': web3.eth.chainId,
            'gas': 2000000,  # Adjust the gas limit as needed
            'gasPrice': web3.toWei('50', 'gwei'),  # Adjust the gas price as needed
            'nonce': web3.eth.getTransactionCount(sender_address),
        })

        # Sign the transaction
        signed_transaction = web3.eth.account.signTransaction(transaction, private_key=sender_private_key)

        # Send the transaction
        transaction_hash = web3.eth.sendRawTransaction(signed_transaction.rawTransaction)

        # Wait for the transaction to be mined
        receipt = web3.eth.waitForTransactionReceipt(transaction_hash)

        return receipt
        print("call Address: %s ABI: %s to %s", (address,abi))


class parseJSON:
    json = None
    def __init__(_json):
        json = _json

    def compileOutput(self):
        print("")

    
class AWS:
    def __init__():
        print("")
    
    def retrivePrivateKey():
        print("set private key")

    def getCIML(self,url):
        #S3 get url
        #parse json data for 
        address = ""
        abi = ""
        return address, abi

if __name__ == "__main__" :
    address = "0xD69B4e5e5A7D5913Ca2d462810592fcd22F6E003"

    print("start program from: %s" % address)


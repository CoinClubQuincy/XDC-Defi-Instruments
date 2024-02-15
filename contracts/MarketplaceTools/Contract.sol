// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title Contract
/// @author R Quincy Jones
/// @notice This contract illustrates how 2 parties can sign an agreement within a smart contract
/// @dev Simple contract meant to be used to sign documents

contract Contract is ERC1155 {
    uint256 public constant PartyA = 0;
    uint256 public constant PartyB = 1;

    uint256 public constant witnessA = 2;
    uint256 public constant witnessB = 3;

    string public DocumentHash = "";
    address public PartyASignature;
    address public PartyBSignature;
    address public WitnessASignature;
    address public WitnessBSignature;

    uint public total_Counter_Proposals =0;
    string public name;

    bool public contractComplete = false;

    event proposal(string,address);
    //Create 2 tokens for Party A-B
    constructor(string memory _DocumentHash,string memory _name, string memory _URI) ERC1155(_URI) {
        DocumentHash = _DocumentHash;
        name = _name;
        _mint(msg.sender,PartyA,1, "");
        _mint(msg.sender,PartyB,1, "");
        _mint(msg.sender,witnessA,1, "");
        _mint(msg.sender,witnessB,1, "");
    }
    //only Party A-B can use functions with their modifier
    modifier PartyA_Sign {
        require(contractComplete == false, "contract has already been signed");
        require(balanceOf(msg.sender,PartyA) == 1);
        _;
    }
    modifier PartyB_Sign {
        require(contractComplete == false, "contract has already been signed");
        require(balanceOf(msg.sender,PartyB) == 1);
        _;
    }
    ///once both parties have signed you can no longer modify the contract
    modifier contractSigned {
        require(contractComplete == false,"Contract has been signed by both parties");
        require(PartyASignature != address(0) && PartyBSignature != address(0), "contract has not been signed by both parties");
        _;
    }

    //this function will compare any data of hash to see if it matches the DocumentHash
    function verify(string memory _DocumentHash)public view returns(bool){
        require(keccak256(abi.encodePacked(_DocumentHash)) == keccak256(abi.encodePacked(DocumentHash)), "Hashes do not match" );
        return true;
    }
    // Party A or party B can make a counter proposal and  reassign the hash
    function counter_proposal_A(string memory _DocumentHash)public  PartyA_Sign returns(bool){
        DocumentHash = _DocumentHash;
        total_Counter_Proposals++;
        return true;
    }
    function counter_proposal_B(string memory _DocumentHash)public PartyB_Sign returns(bool){
        DocumentHash = _DocumentHash;
        total_Counter_Proposals++;
        return true;
    }
    //Both parties can sign and make the contract official
    function sign_proposal()public contractSigned returns(bool,string memory){
        if(balanceOf(msg.sender,PartyA) == 1){
            PartyASignature = msg.sender;
            emit proposal(" A proposal has been made by: ", msg.sender);
            return (true, "Party A has signed Document");
        } else if(balanceOf(msg.sender,PartyB) ==1 ){
            PartyBSignature = msg.sender;
            emit proposal(" A proposal has been made by: ", msg.sender);
            return (true, "Party B has signed Document");
        } else if(balanceOf(msg.sender,witnessA) ==1 ){
            WitnessASignature = msg.sender;
            emit proposal(" A proposal has been made by: ", msg.sender);
            return (true, "Witness A has signed Document");
        } else if(balanceOf(msg.sender,witnessB) ==1 ){
            WitnessBSignature = msg.sender;
            emit proposal(" A proposal has been made by: ", msg.sender);
            return (true, "Witness B has signed Document");
        }
        if(PartyASignature != address(0) && PartyBSignature != address(0) && WitnessASignature != address(0) && WitnessBSignature != address(0)){
            contractComplete = true;
            return (true, "Contract completed");
        } else {
            return (false, "contract not completed");
        }
    }
    
    fallback() external payable {}
    receive() external payable {} 
}

contract ContractDeployer {
    function deployContract(string memory _DocumentHash,string memory _name, string memory _URI) public returns(address){
        address contractAddress; 
        contractAddress = address(new Contract(_DocumentHash,_name, _URI));
        return (contractAddress);
    }
}
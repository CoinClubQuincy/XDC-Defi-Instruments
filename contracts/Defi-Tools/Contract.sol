// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title Contract
/// @author R Quincy Jones
/// @notice This contract illustrates how 2 parties and 2 witnesses can sign an agreement within a smart contract
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
    //Create 4 tokens: Party A-B and Witness A-B. The holder hands them out
    constructor(string memory _DocumentHash,string memory _name, string memory _URI,address _holder) ERC1155(_URI) {
        require(bytes(_DocumentHash).length > 0, "Document hash cannot be empty");
        DocumentHash = _DocumentHash;
        name = _name;
        _mint(_holder,PartyA,1, "");
        _mint(_holder,PartyB,1, "");
        _mint(_holder,witnessA,1, "");
        _mint(_holder,witnessB,1, "");
    }
    //only Party A-B can use functions with their modifier
    modifier PartyA_Sign {
        require(contractComplete == false, "contract has already been signed");
        require(balanceOf(msg.sender,PartyA) == 1, "you do not hold the Party A token");
        _;
    }
    modifier PartyB_Sign {
        require(contractComplete == false, "contract has already been signed");
        require(balanceOf(msg.sender,PartyB) == 1, "you do not hold the Party B token");
        _;
    }

    //this function will compare any data of hash to see if it matches the DocumentHash
    function verify(string memory _DocumentHash)public view returns(bool){
        require(keccak256(abi.encodePacked(_DocumentHash)) == keccak256(abi.encodePacked(DocumentHash)), "Hashes do not match" );
        return true;
    }
    // Party A or party B can make a counter proposal and reassign the hash.
    // Earlier signatures were for the old document, so everyone signs again
    function counter_proposal_A(string memory _DocumentHash)public  PartyA_Sign returns(bool){
        newProposal(_DocumentHash);
        return true;
    }
    function counter_proposal_B(string memory _DocumentHash)public PartyB_Sign returns(bool){
        newProposal(_DocumentHash);
        return true;
    }
    function newProposal(string memory _DocumentHash) internal {
        require(bytes(_DocumentHash).length > 0, "Document hash cannot be empty");
        DocumentHash = _DocumentHash;
        total_Counter_Proposals++;
        PartyASignature = address(0);
        PartyBSignature = address(0);
        WitnessASignature = address(0);
        WitnessBSignature = address(0);
        emit proposal(" A counter proposal has been made by: ", msg.sender);
    }
    //Parties and witnesses each sign once. The fourth signature completes the contract.
    //An address signs for one role only, so nobody can witness their own agreement
    function sign_proposal()public returns(bool,string memory){
        require(contractComplete == false, "contract has already been signed");
        require(msg.sender != PartyASignature && msg.sender != PartyBSignature && msg.sender != WitnessASignature && msg.sender != WitnessBSignature, "you have already signed");

        string memory signed;
        if(balanceOf(msg.sender,PartyA) == 1 && PartyASignature == address(0)){
            PartyASignature = msg.sender;
            signed = "Party A has signed Document";
        } else if(balanceOf(msg.sender,PartyB) == 1 && PartyBSignature == address(0)){
            PartyBSignature = msg.sender;
            signed = "Party B has signed Document";
        } else if(balanceOf(msg.sender,witnessA) == 1 && WitnessASignature == address(0)){
            WitnessASignature = msg.sender;
            signed = "Witness A has signed Document";
        } else if(balanceOf(msg.sender,witnessB) == 1 && WitnessBSignature == address(0)){
            WitnessBSignature = msg.sender;
            signed = "Witness B has signed Document";
        } else {
            revert("you hold no unsigned role");
        }
        emit proposal(" A signature has been made by: ", msg.sender);

        if(PartyASignature != address(0) && PartyBSignature != address(0) && WitnessASignature != address(0) && WitnessBSignature != address(0)){
            contractComplete = true;
            return (true, "Contract completed");
        }
        return (true, signed);
    }
}

contract ContractDeployer {
    //The caller receives the tokens, because this deployer cannot hold them
    function deployContract(string memory _DocumentHash,string memory _name, string memory _URI) public returns(address){
        address contractAddress; 
        contractAddress = address(new Contract(_DocumentHash,_name, _URI, msg.sender));
        return (contractAddress);
    }
}

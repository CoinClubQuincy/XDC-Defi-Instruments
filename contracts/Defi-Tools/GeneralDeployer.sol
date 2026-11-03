
// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

/// @title General Deployer
/// @author R Quincy Jones
/// @notice deploys contracts from bytecode and keeps a list of them

contract ManagerDeployer{
    uint public totalContracts = 0;
    string public deployerName;
    string public deployerDescription;
    bytes public singleContractByteCode;
    bool public singleDeployerActive = false;

    event createNewContract(address indexed creator, address indexed gitXDCContract);

    mapping(uint => Managers) public contracts;
    struct Managers {
        string name;
        string description;
        address contractAddress;
    }

    constructor(string memory _name, string memory _description,bool _singleDeployerActive,bytes memory _singleContractByteCode) {
        deployerName = _name;
        deployerDescription = _description;
        singleDeployerActive = _singleDeployerActive;
        singleContractByteCode = _singleContractByteCode;
    }

    modifier singleDeployer(bytes memory _deployedsingleContractByteCode) {
        if(singleDeployerActive == true){ 
            require(keccak256(singleContractByteCode) == keccak256(_deployedsingleContractByteCode), "this deployer can only deploy a single contract type");
        }
        _;
    }

    function createManager(string memory _name, string memory _description, bytes memory _contractByteCode, bytes memory _constructorArgs) public singleDeployer(_contractByteCode)  returns(address) {
        bytes memory bytecodeWithConstructorArgs = abi.encodePacked(_contractByteCode, _constructorArgs);
        address newContract = createChild(bytecodeWithConstructorArgs);
        contracts[totalContracts] = Managers(_name, _description, newContract);
        emit createNewContract(msg.sender, newContract);
        totalContracts++; 
        return newContract;
    }

    function createChild(bytes memory bytecode) internal returns (address) {
        address child;
        assembly {
            child := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(child != address(0), "deployment failed");
        return child;
    }

    function viewAllContracts() public view returns (Managers[] memory) {
        Managers[] memory contractList = new Managers[](totalContracts);
        for (uint i = 0; i < totalContracts; i++) {
            contractList[i] = contracts[i];
        }
        return contractList;
    }
}
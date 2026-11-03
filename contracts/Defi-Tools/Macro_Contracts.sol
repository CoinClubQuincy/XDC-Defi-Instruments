// SPDX-License-Identifier: GPL-3.0

/// @title MACRO Contract
/// @author R Quincy Jones
/// @notice Keeps a versioned history of a data schema, changed by key holders.
/// @dev Other contracts can read the current schema. Acting on it is left to them

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MACRO is ERC1155 {
    uint public handlerToken;
    bool public initialized = false;
    uint public schemaCount = 0;
    History[] private schemaHistory;

    struct History{
        string[] schema;
    }

    constructor(uint _totalKeys, string memory _URI) ERC1155(_URI) {
        require(_totalKeys > 0, "at least one key is required");
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender, handlerToken, _totalKeys, "");
    }

    modifier Handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }

    modifier Validate(string[] memory _inputSchema){
        require(_inputSchema.length > 0,"Schema must be defined");
        for(uint i = 0; i < _inputSchema.length; i++){
            require(bytes(_inputSchema[i]).length > 0,"Schema must be defined");
        }
        _;
    }

    function initialize(string[] memory _Schema) public Handler Validate(_Schema) returns(bool){
        require(initialized == false,"Contract already initialized");
        initialized = true;
        addSchema(_Schema);
        return true;
    }

    function modifySchema(string[] memory _Schema) public Handler Validate(_Schema) returns(uint){
        require(initialized == true,"Contract not initialized");
        addSchema(_Schema);
        return schemaCount;
    }

    function addSchema(string[] memory _Schema) internal {
        schemaHistory.push();
        schemaHistory[schemaCount].schema = _Schema;
        schemaCount++;
    }

    function viewAllSchemaHistory() public view returns(History[] memory){
        return schemaHistory;
    }

    function viewCurrentSchema() public view returns(string[] memory){
        require(schemaCount > 0,"Contract not initialized");
        return schemaHistory[schemaCount - 1].schema;
    }
} 

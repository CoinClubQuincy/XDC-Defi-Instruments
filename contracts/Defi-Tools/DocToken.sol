// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title A document refrenced as a token on chain
/// @author R Quincy Jones
/// @notice This is a generic rendition of a document renderd as a token 
/// @dev DocuToken

contract Document is ERC1155{
    uint public handlerToken = 0;
    uint public totalDocs = 0;

    constructor(string memory _URI,uint _totalHandles)ERC1155(_URI){
        _mint(msg.sender,handlerToken,_totalHandles, "");
    }

    modifier Handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }

    mapping(uint => DocDictionary) docs;
    struct DocDictionary{
        string name;
        string docHash;
        string description;
        uint token;
    }
    function createDoc(string memory _name,string memory _docHash,string memory _desc) Handler public returns(bool){
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_docHash).length > 0, "Document hash cannot be empty");
        require(bytes(_desc).length > 0, "Description cannot be empty");

        docs[totalDocs] = DocDictionary(_name,_docHash,_desc,totalDocs);
        _mint(msg.sender,totalDocs,1, "");
        totalDocs++;
        return true;
    }
    function viewAllDocs() public view returns(DocDictionary[] memory) {
        DocDictionary[] memory allDocs = new DocDictionary[](totalDocs);
        for (uint i = 0; i < totalDocs; i++) {
            allDocs[i] = docs[i];
        }
        return allDocs;
    }
    function viewToken(uint _token) public view returns (DocDictionary memory) {
        require(_token < totalDocs, "Invalid token");
        return docs[_token];
    }
}

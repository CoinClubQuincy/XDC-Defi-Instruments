// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title Delegate Executor Contract
/// @author R Quincy Jones
/// @notice This is a contract that is meant to execute and manage assets on behalf of a user who does not hold crypto

contract DelegateExecutor is ERC1155{
    uint public handlerToken;  
    uint public pass;

    constructor(string memory _URI,uint _totalKeys,address _mastercontract,string memory _pass) ERC1155(_URI) {
        pass = uint(keccak256(abi.encodePacked(_pass))); //Double Hash
        require(_totalKeys >= 3, "3 key minimum");

        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,1, "");
        _mint(_mastercontract,handlerToken,_totalKeys - 1, "");
    }

    modifier Handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }

    function Send(address _sendTo,uint _amount,string memory _pass)public Handler payable returns(bool){
        require(pass == uint(keccak256(abi.encodePacked(_pass))),"incorect Password");
        payable(_sendTo).transfer(_amount);
        return true;
    }

    function SendXRC20(address _sendTo,uint _amount,string memory _pass,address _tokenAddress)public Handler returns(bool){
        require(pass == uint(keccak256(abi.encodePacked(_pass))),"incorect Password");
        require(_sendTo != address(0), "Invalid address");
        require(_amount > 0, "Amount must be greater than 0");

        IERC20 token;
        token = IERC20(_tokenAddress);

        token.transfer(_sendTo, _amount);
        return true;
    }

    function SendXRC1155(address _sendTo,string memory _pass,address _tokenAddress,uint[] memory _amount,uint[] memory _tokenId,bytes memory data)public Handler returns(bool){
        require(pass == uint(keccak256(abi.encodePacked(_pass))),"incorect Password");
        require(_tokenId.length == _amount.length,"the toal amount of _tokenId  needs to match the total _amount length in each array");
        require(_sendTo != address(0), "Invalid address");
        for(uint i = 0;i <= _tokenId.length;i++){
            require(i > 0, "Amount must be greater than 0");
        }

        IERC1155  token;
        token = IERC1155(_tokenAddress);
        token.safeBatchTransferFrom(address(this), _sendTo, _tokenId, _amount, data);
        return true;
    }
    
    function checkPass(string memory _pass)public view Handler returns(bool){
        require(pass == uint(keccak256(abi.encodePacked(_pass))),"incorect Password");
        return true;
    }

    function changePass(string memory _oldPass,string memory _newPass)public Handler returns(bool){
        require(pass == uint(keccak256(abi.encodePacked(_oldPass))),"incorect Password");
        pass = uint(keccak256(abi.encodePacked(_newPass)));
        return true;
    }

    function delegateCall(address _contract,string memory _function, uint[] memory _call) public payable returns(bool,bytes memory){
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature(_function, _call));
        return (success,data);
    }

    //ERC1155Received fuctions
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }


    fallback() external payable {}
    receive() external payable {} 
}
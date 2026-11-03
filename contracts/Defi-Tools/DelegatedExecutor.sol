// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title Delegate Executor Contract
/// @author R Quincy Jones
/// @notice This is a contract that is meant to execute and manage assets on behalf of a user who does not hold crypto.
/// Every key has full control. There is no password, because anything sent to a public chain is public

contract DelegateExecutor is ERC1155{
    using SafeERC20 for IERC20;

    uint public handlerToken;  

    constructor(string memory _URI,uint _totalKeys,address _mastercontract) ERC1155(_URI) {
        require(_totalKeys >= 3, "3 key minimum");

        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender,handlerToken,1, "");
        _mint(_mastercontract,handlerToken,_totalKeys - 1, "");
    }

    modifier Handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }

    function Send(address _sendTo,uint _amount)public Handler payable returns(bool){
        require(_sendTo != address(0), "Invalid address");
        require(_amount > 0, "Amount must be greater than 0");
        (bool sent,) = payable(_sendTo).call{value: _amount}("");
        require(sent, "Payment failed");
        return true;
    }

    function SendXRC20(address _sendTo,uint _amount,address _tokenAddress)public Handler returns(bool){
        require(_sendTo != address(0), "Invalid address");
        require(_amount > 0, "Amount must be greater than 0");

        IERC20(_tokenAddress).safeTransfer(_sendTo, _amount);
        return true;
    }

    function SendXRC1155(address _sendTo,address _tokenAddress,uint[] memory _amount,uint[] memory _tokenId,bytes memory data)public Handler returns(bool){
        require(_tokenId.length == _amount.length,"the toal amount of _tokenId  needs to match the total _amount length in each array");
        require(_tokenId.length > 0, "Nothing to send");
        require(_sendTo != address(0), "Invalid address");
        for(uint i = 0;i < _amount.length;i++){
            require(_amount[i] > 0, "Amount must be greater than 0");
        }

        IERC1155(_tokenAddress).safeBatchTransferFrom(address(this), _sendTo, _tokenId, _amount, data);
        return true;
    }

    /// @notice Calls another contract on behalf of this one. This replaces a delegatecall, which ran
    /// outside code with this contract's own storage and balance and could be used by anyone
    function executeCall(address _contract,uint _value,bytes memory _data) public Handler payable returns(bytes memory){
        require(_contract.code.length > 0, "Target is not a contract");
        (bool success, bytes memory result) = _contract.call{value: _value}(_data);
        require(success, "Call failed");
        return result;
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

    receive() external payable {} 
}

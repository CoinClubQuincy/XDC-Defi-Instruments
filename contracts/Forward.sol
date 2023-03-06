// There are four key differences between forward vs future contracts: 
// forwards are non-transferable,customizable, and illiquid, 
// as well as exposed to counterparty default risk.
//  Details like quantity,expiration date, and price can be adjusted as agreed upon in the contract between the two parties privately.

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//Smart contract
contract Forward is ERC1155 {
    uint256 public constant saleToken = 0;

    constructor() ERC1155("https://thisissomeMetaData/{id}.json") {
        _mint(msg.sender,saleToken,1, "");
    }
    
    // Crreate func to list token price and drop commodities tokn in forwards contract | as well as collatoral limit

    // create sales function to but contract 


    // token holder can redeem contract once time has elaps
}
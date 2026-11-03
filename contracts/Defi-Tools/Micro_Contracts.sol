// SPDX-License-Identifier: GPL-3.0

/// @title MICRO Contract
/// @author R Quincy Jones
/// @notice Holds rate parameters, changed by key holders, for other contracts to read.
/// @dev It is also an open deployer, through ManagerDeployer

pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./GeneralDeployer.sol";

contract MICRO is ManagerDeployer, ERC1155 {
    uint public handlerToken;
    bool public initialized = false;
    Parameters public parameters;
    struct Parameters {
        uint256 transacted_funds_rate;
        uint256 liquid_invoice_intrest_rate;
    }

    constructor(string memory _name, string memory _description, uint _totalKeys, string memory _URI) ManagerDeployer(_name, _description, false, "") ERC1155(_URI) {
        require(_totalKeys > 0, "at least one key is required");
        handlerToken = uint(keccak256(abi.encodePacked(_URI)));
        _mint(msg.sender, handlerToken, _totalKeys, "");
    }

    modifier Handler{
        require(balanceOf(msg.sender,handlerToken) >= 1, "user does not hold handler token");
        _;
    }

    function initialize(uint set_transacted_funds_rate, uint set_liquid_invoice_intrest_rate) public Handler returns(bool) {
        require(!initialized, "Already initialized");
        parameters.transacted_funds_rate = set_transacted_funds_rate;
        parameters.liquid_invoice_intrest_rate = set_liquid_invoice_intrest_rate;
        initialized = true;
        return true;
    }  
    function view_single_parameter(string memory parameter) public view returns (uint256) {
        if (isParameter(parameter, "transacted_funds_rate")) { return parameters.transacted_funds_rate; }
        if (isParameter(parameter, "liquid_invoice_intrest_rate")) { return parameters.liquid_invoice_intrest_rate; }
        revert("Parameter not found");
    }
    function view_all_parameters() public view returns (Parameters memory) {
        return parameters;
    }
    function set_single_parameter(string memory parameter, uint256 value) public Handler returns(Parameters memory) {
        require(initialized, "Not initialized");
        if (isParameter(parameter, "transacted_funds_rate")) {
            parameters.transacted_funds_rate = value;
        } else if (isParameter(parameter, "liquid_invoice_intrest_rate")) {
            parameters.liquid_invoice_intrest_rate = value;
        } else {
            revert("Parameter not found");
        }
        return parameters;
    }
    function isParameter(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

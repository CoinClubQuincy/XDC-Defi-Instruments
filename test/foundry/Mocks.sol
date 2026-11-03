// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC1155 {
    constructor() ERC1155("https://example.com/{id}.json") {}

    function mint(address to, uint id, uint amount) external {
        _mint(to, id, amount, "");
    }
}

contract MockCoin is ERC20 {
    constructor() ERC20("Mock", "MOCK") {}

    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}

/// Refuses every payment, like a contract with no way to receive money
contract RefusesMoney {
    function callWith(address target, uint value, bytes memory data) external payable {
        (bool ok,) = target.call{value: value}(data);
        require(ok, "call failed");
    }

    receive() external payable {
        revert("no thanks");
    }
}

contract Counter {
    uint public count;
    uint public paid;

    function increase() external payable {
        count++;
        paid += msg.value;
    }
}

/// Takes part in sales but refuses every token sent to it
contract RefusesTokens {
    function callWith(address target, uint value, bytes memory data) external payable {
        (bool ok,) = target.call{value: value}(data);
        require(ok, "call failed");
    }

    receive() external payable {}

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        revert("no tokens");
    }
}

/// Uses up all the gas it is given when it receives a token
contract BurnsGasOnTokens {
    function callWith(address target, uint value, bytes memory data) external payable {
        (bool ok,) = target.call{value: value}(data);
        require(ok, "call failed");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        while (true) {}
        return bytes4(0);
    }
}

contract PausableToken is ERC1155 {
    bool public paused;

    constructor() ERC1155("https://example.com/{id}.json") {}

    function mint(address to, uint id, uint amount) external {
        _mint(to, id, amount, "");
    }

    function setPaused(bool value) external {
        paused = value;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
        require(!paused, "paused");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

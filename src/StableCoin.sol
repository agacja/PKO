// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";

contract StableCoin is ERC20, Ownable {
    string private _name;
    string private _symbol;

    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setName(string memory newName) public onlyOwner {
        _name = newName;
    }

    function setSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }
}

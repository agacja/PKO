// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solady/scrc/token/ERC20.sol";
import "solady/src/auth/Ownable.sol";


contract AkcjaToken
 is ERC20 {
    string private _name;
    string private _symbol;

    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    

    function name() public view override returns (string memory) {
        return _name;
    }

    // Overriding the symbol function to return the custom token symbol.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    //funkcja do pauzowania kontkretnych



}
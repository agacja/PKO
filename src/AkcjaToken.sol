// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error NotAllowed();
error SaleClosed();

import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";

contract AkcjaToken is ERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private State;
  
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

 function burn(address _customer, uint256 _amount) public onlyOwner {
        _burn(_customer, _amount);
    }

    function setSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }

    function setStateforToken(uint8 value) external onlyOwner {
        State = value;
    }



function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    if (State == 0) revert SaleClosed();

    return super.transfer(recipient, amount);
}

// Override transferFrom function
function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    if (State == 0) revert SaleClosed();

    return super.transferFrom(sender, recipient, amount);
}}


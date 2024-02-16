pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract StableCoin is ERC20Upgradeable {

    function initialize(string memory name, string memory symbol)  public initializer {
        __ERC20_init(name, symbol);
        _mint( msg.sender, 1000000000); 
    }
}
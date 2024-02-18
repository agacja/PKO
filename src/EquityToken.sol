// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "solady/auth/Ownable.sol";
import "../src/AkcjaToken.sol";
import "../src/ITokenFactory.sol";

contract EquityToken is Ownable {
    function createAkcja(
        string calldata name,
        string calldata sym,
        uint256 totalSupply
    ) external payable returns (address) {
        AkcjaToken akcja = new AkcjaToken(name, sym, msg.sender, totalSupply);
        assembly {
            mstore(0, akcja)
            return(0, 0x20)
        }
    }
}

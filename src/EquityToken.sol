// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./IAllowedList.sol";
import "../src/AkcjaToken.sol";

contract EquityToken is  OwnableUpgradeable, PausableUpgradeable {



    function createToken(address company, string memory name, string memory symbol, uint256 initialSupply) public returns (address) {
       AkcjaToken newToken = new AkcjaToken(initialSupply);
        return address(newToken);
        
    }

function createAkcja(
    string calldata name,
    string calldata sym,
    uint256 initialSupply
  
) external payable returns (address) {


     EquityTok akcja =
        new  EquityTok( initialSupply);
          {
            ///@solidity memory-safe-assembly
            assembly {
                let success := call(gas(), akcja, 0, 0, 0, 0, 0)
                if iszero(success) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

    assembly {
            mstore(0, akcja)
            return(0, 0x20)

        }

}}

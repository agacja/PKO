// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "solady/auth/Ownable.sol";
import "../src/AkcjaToken.sol";
import "../src/ITokenFactory.sol";
contract EquityToken is Ownable {



    function createToken(string memory name, string memory symbol, uint256 initialSupply) public  {
       AkcjaToken newToken = new AkcjaToken(initialSupply);
       newToken.setName(name);
       newToken.setSymbol(symbol);
        
    }


  function createAkcja(
    string calldata name,
    string calldata sym,
    uint256 initialSupply
  
) external payable returns (address) {

     AkcjaToken akcja =
        new  AkcjaToken(initialSupply);
        akcja.setName(name);
        akcja.setSymbol(sym);

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

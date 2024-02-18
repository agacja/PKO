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


     Coin akcja =
        new Coin{ value: msg.value}( name, sym, msg.sender, totalSupply);
       // if (teamBps < 10000) {
            ///@solidity memory-safe-assembly
          //  assembly {
             //   let success := call(gas(), meme, 0, 0, 0, 0, 0)
            //    if iszero(success) {
            //        returndatacopy(0, 0, returndatasize())
            //        revert(0, returndatasize())
            //    }
          //  }
     //   }

    assembly {
            mstore(0, akcja)
            return(0, 0x20)

        }

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./IAllowedList.sol";

contract EquityToken is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    string public baseURI;

    IAllowedList allowedList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier notPaused() {
        require(!paused(), "EquityToken: contract is paused");
        _;
    }


function init(
   
    string calldata name,
    string calldata sym,
    //need to be allowlisted
    IAllowedList _iAllowedList,
    uint256 totalSupply,
    bytes32 salt
) external payable returns (address) {

    _validateCommitment(salt, name);

     Coin init =
        new Coin{ salt: salt, value: msg.value}(name, sym, totalSupply * 1e18, msg.sender, teamBps, liquidityLockPeriodInSeconds);
        if (teamBps < 10000) {
            ///@solidity memory-safe-assembly
            assembly {
                let success := call(gas(), meme, 0, 0, 0, 0, 0)
                if iszero(success) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

    collectiontokentype[_nft] = address(meme);

    assembly {
            mstore(0, meme)
            return(0, 0x20)

        }

    }



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error NotAllowed();
error SaleClosed();

import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";

contract AkcjaToken is ERC20, Ownable {
    error LiquidityLocked();
    error InvalidInitializationParams();

    // uint256 private constant INVALID_INITIALIZATION_PARAMS_SELECTOR = 0x7676b397;
    // uint256 private constant _TRANSFER_EVENT_SIGNATURE = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    //  uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    bytes32 immutable _NAME;
    bytes32 immutable _SYMBOL;

    constructor(
        string memory name_,
        string memory sym,
        address _deployer,
        uint256 fullTotalSupply
    ) {
        bytes32 _name;
        bytes32 _symbol;
        ///@solidity memory-safe-assembly
        assembly {
            let nameLen := mload(name_)
            let symLen := mload(sym)

            // load the last byte encoding length of each string plus the next 31 bytes
            _name := mload(add(31, name_))
            _symbol := mload(add(31, sym))
            // add timestamp to liquidity lock period
        }
        // assign owner
        _initializeOwner(_deployer);
        _mint(_deployer, fullTotalSupply);

        // assign immutables

        _NAME = _name;
        _SYMBOL = _symbol;
    }

      function mint( uint256 amount) external onlyOwner() {
        
        _mint(owner, amount);
    }

    function name() public view override returns (string memory) {
        bytes32 name_ = _NAME;
        ///@solidity memory-safe-assembly
        assembly {
            mstore(0, 0x20)
            mstore(0x3f, name_)
            // can't override this as external, so note that this will break internal methods that try to call as public
            return(0, 0x60)
        }
    }

    function symbol() public view override returns (string memory) {
        bytes32 symbol_ = _SYMBOL;
        ///@solidity memory-safe-assembly
        assembly {
            mstore(0, 0x20)
            mstore(0x3f, symbol_)
            // can't override this as external, so note that this will break internal methods that try to call as public
            return(0, 0x60)
        }
    }
}

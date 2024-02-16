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

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        IAllowedList _iAllowedList
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC20Pausable_init();
        baseURI = _baseURI;
        allowedList = _iAllowedList;
    }

    function creatItem(address _customer, uint256 _amount) public onlyOwner {
        _mint(_customer, _amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(address _customer, uint256 _amount) public onlyOwner {
        //solhint-disable-next-line max-line-length
        _burn(_customer, _amount);
    }

    function isInAllowedList(address _address) external view {
        _isInAllowedList(_address);
    }

    function checkAllowedList(address _address) external view returns (bool) {

        return allowedList.checkAllowedList(_address);
    }

    function _isInAllowedList(address _address) internal view {

        require(allowedList.checkAllowedList(_address),"EquityToken: address is not on allowed list");
    }
    
   function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(allowedList.checkAllowedList(to),"EquityToken: address is not on allowed list");
        require(!paused(), "EquityToken: token transfer while paused");
    }
    uint256[50] private __gap;

}
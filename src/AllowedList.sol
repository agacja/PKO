pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IAllowedList.sol";

contract AllowedList is IAllowedList, OwnableUpgradeable, PausableUpgradeable {
    
    mapping (address => bool) private _allowedList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function isInAllowedList(address _address) external view override {
        _isInAllowedList(_address);
    }

    function _isInAllowedList(address _address) internal view {
        require(_allowedList[_address],"AllowedList: address is not on allowed list");
    }

    function addToAllowedList(address _address) external override notPaused onlyOwner {
        _allowedList[_address] = true;
        emit AddToAllowedList(_address);
    }

    function removeFromAllowedList(address _address) external override notPaused onlyOwner {
        _isInAllowedList(_address);
        delete _allowedList[_address];
        emit RemoveFromAllowedList(_address);
    }

    function checkAllowedList(address _address) external override view returns (bool) {
        return _allowedList[_address];
    }

    function pause() public notPaused onlyOwner {
        _pause();
    }

    function unpause() public onlyWhenPaused onlyOwner {
        _unpause();
    }

    modifier notPaused() {
        require(!paused(), "AllowedList: contract is paused");
        _;
    }

    modifier onlyWhenPaused() {
        require(paused(), "AllowedList: contract is not paused");
        _;
    }

}
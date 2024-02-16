pragma solidity ^0.8.18;

interface IAllowedList{
    event AddToAllowedList(address indexed _address);
    event RemoveFromAllowedList(address indexed _address);

    function isInAllowedList(address _address) external;
    function addToAllowedList(address _address) external;
    function removeFromAllowedList(address _address) external;
    function checkAllowedList(address _address) external view returns (bool);
}
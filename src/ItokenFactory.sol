// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20TokenFactory {
    function createToken(string memory _tokenName, string memory _tokenSymbol) external returns (address);
}
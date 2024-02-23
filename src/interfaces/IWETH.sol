//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import "./IERC20Metadata.sol";

interface IWETH is IERC20Metadata {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    receive() external payable;
    fallback() external payable;
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
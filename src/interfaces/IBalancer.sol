// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "./IFlashLoanRecipient.sol";
import "./IERC20.sol";

interface IBalancer {
    function flashLoan(IFlashLoanRecipient recipient, IERC20[] memory tokens, uint256[] memory amounts, bytes memory userData) external;
}
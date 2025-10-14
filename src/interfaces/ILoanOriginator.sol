// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 @title IOracle
 @dev oracle interface for the CFC contract
**/
interface ILoanOriginator {
        function payLoan(address _borrower, uint256 _amount) external;
        function withdrawLoan(address _to, uint256 _amount) external;
}
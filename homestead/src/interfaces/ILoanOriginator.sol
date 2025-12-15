// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 @title ILoanOriginator
 @dev interface for the loan originator
**/
interface ILoanOriginator {
        function payLoan(address _borrower, uint256 _amount) external;
        function withdrawLoan(address _to, uint256 _amount) external;
        function getCurrentAmountTaken(address _to) external view returns(uint256 _amountTaken);
}
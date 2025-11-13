// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Collateral contract
 */
interface ICollateral {
        function getCollateralBalance(address _borrower) external returns(uint256);
        function sendCollateral(address _to, address _from, uint256 _amount) external;
}

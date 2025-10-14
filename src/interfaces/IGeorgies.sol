// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC20.sol";
/**
 * @dev subset Georgies interface
 */
interface IGeorgies is IERC20{
    function burn(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}

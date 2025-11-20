// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./Token.sol";
                                                                                                         
/**
 @title StaingContract
 @dev allows you to stake your georgies so you get Henries as a reward
 */
contract StakingContract is Token{

    /*Storage*/
    IERC20 public georgies; 
    IERC20 public henries;

    /*Events*/
    event Stake(address _stake, uint256 _amount);
    event Unstake(address _staker, uint256 _amount);

    /*Functions*/
    /**
     * @dev starts the Staking Contract
     * @param _henries the address of the henries token
     * @param _georgies address of georgies token
     * must also initialize the treasury contract in the system to fully start
     */
    constructor(address _georgies, address _henries, string memory _name, string memory _symbol) Token(_name,_symbol){
        henries = IERC20(_henries);
        georgies = IERC20(_georgies);
    }
    
    function stake(uint256 _amount) external{
        require(georgies.transferFrom(msg.sender, address(this), _amount));
        _mint(msg.sender,_amount);
        emit Stake(msg.sender,_amount);
    }

    function  unstake(uint256 _amount) external{
        require(balance[msg.sender] >= _amount, "must have tokens");
        uint256 _pctOwnership = balance[msg.sender] * 1 ether / supply;
        _burn(msg.sender,_amount);
        uint256 _gOut = _pctOwnership * georgies.balanceOf(address(this)) / 1 ether;
        if(_gOut > 0){
            georgies.transfer(msg.sender, _gOut);
        }
        uint256 _hOut = _pctOwnership * henries.balanceOf(address(this)) / 1 ether;
        if(_hOut > 0){
            henries.transfer(msg.sender, _hOut);
        }
        emit Unstake(msg.sender, _amount);
    }
}

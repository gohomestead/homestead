//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./interfaces/ILoanOriginator.sol";

// ░▒▓████████▓▒░▒▓███████▓▒░░▒▓████████▓▒░░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
//    ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░       ▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
//    ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░       ▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
//    ░▒▓█▓▒░   ░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓████████▓▒░▒▓██████▓▒░░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░  
//    ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░     
//    ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░     
//    ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░     
                                                                                                                       
                                                                                                                       
//the system literally can't pay off all loans.  If you mint 100 Georgies, but owe 102 next year, what's the deal? But that's ok.  
//The treasury contract is the balance.  It collects this extra interest and uses it's preiveleged role 
// as a stability mechanism in the system, with its main role is to sell to the market so other people can pay off their loans
//if the price of Georgies is too high, we take out new loans and sell to the market
//starts off with little ability to go in other direction, but it can also help there
/**
 @title
 @dev treasury contract for monetary policy
**/
contract Treasury{

    /*Storage*/
    IERC20 public georgies;

    address public admin;//admin can send funds from this contract
    uint256 public totalOut;//total amount given out from the contract

    mapping(address => uint256) public fundsGivenByAddress;

    /*Events*/
    event AdminChanged(address _newAdmin);
    event FundsDistributed(address _to, uint256 _amount);

    /*Functions*/
    /**
     * @dev constructor to initialize contract and token
     */
    constructor(address _admin, address _georgies){
        admin = _admin;
        georgies = IERC20(_georgies);
    }

    /**
     * @dev function to change the admin
     * @param _newAdmin address of new admin
     */
    function changeAdmin(address _newAdmin) external{
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev function to transfer tokens for treasury functions
     * @param _to destination of tokens
     * @param _amount of tokens
     */
    function doMonetaryPolicy(address _to, uint256 _amount) external{
        require(msg.sender == admin);
        require(_amount <= georgies.balanceOf(address(this)));
        georgies.transfer(_to,_amount);
        fundsGivenByAddress[_to] = fundsGivenByAddress[_to] += _amount;
        totalOut += _amount;
        emit FundsDistributed(_to, _amount);
    }

    /*Getters*/
    /**
     * @dev function to retrieve funds given to each address
     * @param _addy address of interest
     * @return uint256 of number of georgies
     */
    function getFundsByAddress(address _addy) external view returns(uint256){
        return fundsGivenByAddress[_addy];
    }
}
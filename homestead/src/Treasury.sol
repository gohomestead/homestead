//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./interfaces/ILoanOriginator.sol";

//it literally can't pay off all it's loans.  But that's ok.  
//its role is to sell to the market so other people can pay off their loans
//if the price of Georgies is too high, we take out new loans and sell to the market
//starts off with little ability to go in other direction, but can also help to 
// stabilize georgies price if necessary (auto?)
//should we have USDC mint ability?  
// allows anyone to arb
/**
 @title
 @dev treasury contract for monetary policy
**/
contract Treasury{

    //storage
    address public admin;
    IERC20 public georgies;
    uint256 public totalOut;
    mapping(address => uint256) public fundsGivenByAddress;

    //events
    event AdminChanged(address _newAdmin);
    event FundsDistributed(address _to, uint256 _amount);

    //functions
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
        georgies.transfer(_to,_amount);
        fundsGivenByAddress[_to] = fundsGivenByAddress[_to] += _amount;
        totalOut += _amount;
        emit FundsDistributed(_to, _amount);
    }
    //have a way to payBackLoan? or just send it here? 

    function getFundsByAddress(address _addy) external view returns(uint256){
        return fundsGivenByAddress[_addy];
    }
}
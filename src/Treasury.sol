//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import "./interfaces/ILoanOriginator.sol";
import "./interfaces/IERC20.sol";

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
    address admin;
    address wallet;
    IERC20 georgies;
    ILoanOriginator loanContract;

    event LoanTakenByTreasury(uint256 _amount);
    event FundsGivenToSeller(address _to, uint256 _amount);
    event LoanPaidBackByTreasury(uint256 _amount);
    //functions
    /**
     * @dev constructor to initialize contract and token
     */
    constructor(address _admin, address _loanContract, address _georgies){
        admin = _admin;
        loanContract = ILoanOriginator(_loanContract);
        georgies = IERC20(_georgies);
    }

    function changeWallet(address _newWallet) external{
        require(msg.sender == admin);
        wallet = _newWallet;
    }

    function takeOutNewLoan(uint256 _amount) external{
        require(msg.sender == admin);
        loanContract.withdrawLoan(address(this),_amount);
        georgies.transfer(wallet,_amount);
        emit LoanTakenByTreasury(_amount);
    }  

    function payOffLoan(uint256 _amount) external{
        require(msg.sender == wallet);
        loanContract.payLoan(address(this),_amount);
        emit LoanPaidBackByTreasury(_amount);

    }
}
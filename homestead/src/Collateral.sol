// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./interfaces/ILoanOriginator.sol";

contract Collateral {
    /*Storage*/
    IERC20 public collateralToken;
    ILoanOriginator public loanContract;
    
    address public admin;
    address public proposedAdmin; 
    address public proposedLoanContract;
    uint256 public proposalTime;
    uint256 public totalCollateral;

    mapping(address => uint256) public collateralBalance;

    /*Events*/
    event CollateralDeposited(address _borrower, uint256 _amount);
    event CollateralWithdrawn(address _borrower, uint256 _amount);
    event SystemUpdateProposal(address _proposedAdmin, address _proposedLoanContract);
    event SystemVariablesUpdated(address _admin, address _loanContract);
    
    /*Functions*/
    constructor(address _collateralToken, address _loanContract, address _admin){
        loanContract = ILoanOriginator(_loanContract);
        collateralToken = IERC20(_collateralToken);
        admin = _admin;
    }

    function depositCollateral(uint256 _amount) external{
        require(collateralToken.transferFrom(msg.sender,address(this), _amount));
        collateralBalance[msg.sender] = collateralBalance[msg.sender]  + _amount;
        totalCollateral += _amount;
        emit CollateralDeposited(msg.sender, _amount);
    }

    /**
     * @dev function to finalize an update after 7 days
     */
    function finalizeUpdate() external{
        require(msg.sender == admin);
        require(block.timestamp - proposalTime > 7 days);
        loanContract = ILoanOriginator(proposedLoanContract);
        admin = proposedAdmin;
        emit SystemVariablesUpdated(admin, proposedLoanContract);
    }

    function redeemCollateral(uint256 _amount) external{
        uint256 _amountTaken;
        _amountTaken = loanContract.getCurrentAmountTaken(msg.sender);
        require((collateralBalance[msg.sender] - _amount) > _amountTaken);
        collateralBalance[msg.sender] = collateralBalance[msg.sender]  - _amount;
        totalCollateral -= _amount;
        collateralToken.transfer(msg.sender,_amount);
        emit CollateralWithdrawn(msg.sender,_amount);
    }

    //allows the loanContract to sendOutTheUSDC at cost if there is a default
    function sendCollateral(address _from, address _to, uint256 _amount) external{
        require(msg.sender == address(loanContract));
        if(_amount > collateralBalance[_from]){
            _amount = collateralBalance[_from];
        }
        collateralToken.transfer(_to,_amount);
        collateralBalance[_from] = collateralBalance[_from]  - _amount;
        totalCollateral -= _amount;
        emit CollateralWithdrawn(_from,_amount);
    }   

    /**
     * @dev function to change the admin/loandContract
     * @param _proposedAdmin address of new admin
     * @param _proposedLoanContract address of new loan contract
     */
    function updateSystemVariables(address _proposedAdmin, address _proposedLoanContract) external{
        require(msg.sender == admin);
        proposalTime = block.timestamp;
        proposedAdmin = _proposedAdmin;
        proposedLoanContract = _proposedLoanContract;
        emit SystemUpdateProposal(_proposedAdmin, _proposedLoanContract);
    }

    /*Getters*/
    function getCollateralBalance(address _borrower) external view returns(uint256){
        return collateralBalance[_borrower];
    }
}

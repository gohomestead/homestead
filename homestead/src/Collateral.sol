// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./interfaces/ILoanOriginator.sol";

contract Collateral {

    address public admin; 
    mapping(address => uint256) public collateralBalance;
    IERC20 public collateralToken;
    uint256 public totalCollateral;
    ILoanOriginator public loanContract;

    event CollateralDeposited(address _borrower, uint256 _amount);
    event CollateralWithdrawn(address _borrower, uint256 _amount);
    event SystemUpdateProposal(address _proposedAdmin, address _proposedLoanContract);
    event SystemVariablesUpdated(address _admin, address _loanContract);

    constructor(address _collateralToken, address _loanContract, address _admin){
        loanContract = ILoanOriginator(_loanContract);
        collateralToken = IERC20(_collateralToken);
        admin = _admin;
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
    
    /**
     * @dev function to finalize an update after 7 days
     */
    function finalizeUpdate() external{
        require(msg.sender == admin);
        require(block.timestamp - proposalTime > 7 days);
        loanContract = proposedLoanContract;
        admin = proposedAdmin;
        emit SystemVariablesUpdated(admin, loanContract);
    }

    function depositCollateral(uint256 _amount){
        require(collateralToken.transferFrom(msg.sender,address(this), _amount));
        collateralBalance[msg.sender] = collateralBalance[msg.sender]  + _amount;
        totalCollateral += _amount;
        emit CollateralDeposited(msg.sender, _amount);
    }

    function redeemCollateral(uint256 _amount){
        uint256 _amountTaken;
        (,_amountTaken,,) = loanContract.getCreditDetails(msg.sender);
        require((collateralBalance[msg.sender] - _amount) * .95 > _amountTaken);
        collateralBalance[msg.sender] = collateralBalance[msg.sender]  - _amount;
        totalCollateral -= _amount;
        collateralToken.transfer(msg.sender,_amount);
        emit CollateralWithdrawn(msg.sender,_amount);
    }

    //allows the loanContract to sendOutTheUSDC at cost if there is a default
    function sendCollateral(address _to, address _from, uint256 _amount) external{
        require(msg.sender == loanContract);
        if(_amount > collateralBalance[_from]){
            _amount = collateralBalance[_from];
        }
        collateralToken.transfer(_to,_amount);
        collateralBalance[_from] = collateralBalance[_from]  - _amount;
        totalCollateral -= _amount;
        emit CollateralWithdrawn(_from,_amount);
    }   

    function getCollateralBalance(address _borrower) external returns(uint256){
        return collateralBalance[_borrower];
    }
}

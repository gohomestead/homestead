// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IGeorgies.sol";
import "./interfaces/ICollateral.sol";

//   ___ ___                                 __                     .___
//  /   |   \  ____   _____   ____   _______/  |_  ____ _____     __| _/
// /    ~    \/  _ \ /     \_/ __ \ /  ___/\   __\/ __ \\__  \   / __ | 
// \    Y    (  <_> )  Y Y  \  ___/ \___ \  |  | \  ___/ / __ \_/ /_/ | 
//  \___|_  / \____/|__|_|  /\___  >____  > |__|  \___  >____  /\____ | 
//        \/              \/     \/     \/            \/     \/      \/ 
/**
 @title LoanOriginator
 @dev the incentive token for the homestead protocol
**/
contract LoanOriginator {
    //storage
    struct LineOfCredit {
        bool isCollateral;
        uint256 amount;//amount of credit a borrower is approved for
        uint256 amountTaken;//amount taken out or outstanding
        uint256 calcDate;//last date interest was calculated
        uint256 interestRate;//interest rate on loan; 100,000 = 100%
        uint256 startDate;
    }

    ICollateral public collateralContract;
    IGeorgies public  georgies;//address of base georgies token

    address public admin;//admin of the system, can change feeContract, treasury, repay loans (default), approve loans, and change fee
    address public feeContract;//address that accumulates system fees
    address public proposedAdmin;
    address public proposedCollateralContract;
    address public proposedFeeContract;
    address public proposedTreasury;
    address public treasury;//address that gets interest accumulation of georgies (to balance system)
    uint256 constant public YEAR = 86400*365;
    uint256 public collateralDiscount;//pct that collateral counts for 100,000 = 100%
    uint256 public fee; //fee paid on minting and burning of georgies; 100,000 = 100%  
    uint256 public proposedCollateralDiscount;
    uint256 public proposedFee;
    uint256 public proposalTime;

    mapping(address => LineOfCredit) public linesOfCredit;

    //events
    event SystemUpdateProposal(address _admin, address _collateralContract, address _feeContract, address _treasury, uint256 _fee, uint256 _collateralDiscount);
    event SystemVariablesUpdated(address _admin, address _collateralContract, address _feeContract, address _treasury, uint256 _fee, uint256 _collateralDiscount);
    event LineOfCreditSet(address _to, uint256 _amount, uint256 _rate);
    event LoanPayment(address _borrower, uint256 _amount);
    event LoanTaken(address _to, uint256 _amount);

    //functions
    /**
     * @dev starts the Loan Contract
     * @param _feeContract the address of the feeContract
     * @param _georgies address of georgies token
     * @param _admin admin in the contract
     * must also initialize the treasury contract in the system to fully start
     */
    constructor(address _feeContract, address _georgies, address _admin){
        feeContract = _feeContract;
        georgies = IGeorgies(_georgies);
        admin = _admin;
    }

    /**
     * @dev function to finalize an update after 7 days
     */
    function finalizeUpdate() external{
        require(msg.sender == admin);
        require(block.timestamp - proposalTime > 7 days);
        collateralContract = ICollateral(proposedCollateralContract);
        admin = proposedAdmin;
        feeContract = proposedFeeContract;
        treasury = proposedTreasury;
        fee = proposedFee;
        collateralDiscount = proposedCollateralDiscount;
        emit SystemVariablesUpdated(admin,address(collateralContract), feeContract, treasury, fee, collateralDiscount);
    }

    function init(address _collateralContract, address _treasury, uint256 _fee, uint256 _collateralDiscount) external{
        require(treasury == address(0));
        require(_treasury != address(0));
        collateralContract = ICollateral(_collateralContract);
        treasury = _treasury;
        fee = _fee;
        collateralDiscount = _collateralDiscount;
    }
    
    /**
     * @dev function to pay back a loan once taken out
     * @param _borrower address of person paying back loan
     * @param _amount amount of loan to pay back (fee included in this amount)
     */
    function payLoan(address _borrower, uint256 _amount) external{
        LineOfCredit storage _l  = linesOfCredit[_borrower];
        require(_l.amountTaken > 0);
        uint256 _currentValue =  _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000; 
        uint256 _interest = _currentValue - _l.amountTaken;
        uint256 _fee;
        uint256 _paymentAmount;
        bool _isDefault;
        if(_l.isCollateral){
                uint256 _collateral = collateralContract.getCollateralBalance(_borrower);
                uint256 _adjCollateral = _collateral * collateralDiscount/100000;
                if(_currentValue <= _adjCollateral){
                    require(msg.sender == _borrower || msg.sender == admin, "must be authorized");
                }
                else{
                    _isDefault = true;
                    if(_currentValue >= _collateral){
                        _currentValue = _collateral;
                    }
                }
        }
        else{
            require(msg.sender == _borrower || msg.sender == admin, "must be authorized");
        }
        if(_amount > _currentValue + _currentValue * fee/100000){
            _fee = _currentValue  * fee/100000;
            _paymentAmount = _currentValue;
        }
        else{
            _fee = _amount * fee/100000;
            _paymentAmount = _amount -_fee;
        }
        require(georgies.transferFrom(msg.sender,feeContract,_fee), "transfer failed");
        georgies.burn(msg.sender,_paymentAmount);
        if(_interest > 0){
            georgies.mint(treasury,_interest);
        }
        if(_isDefault){
            collateralContract.sendCollateral(msg.sender,_borrower,_paymentAmount);
        }
        _l.amountTaken = _currentValue - _paymentAmount;
        _l.calcDate = block.timestamp;
        emit LoanPayment(_borrower,_amount);
    } 

    /**
     * @dev function for admin to set a new line of credit for a borrower
     * @param _to address of borrower to mint tokens to
     * @param _amount amount of tokens to mint to borrower
     * @param _rate interest rate given to loan
     * @param _isCollateral bool for whether or not is for onchain collateral or off-chain collateral loans
     */
    function setLineOfCredit(address _to, uint256 _amount, uint256 _rate, bool _isCollateral) external{
        require(msg.sender == admin);
        LineOfCredit storage _l  = linesOfCredit[_to];
        //require(_l.amountTaken == 0);//change? 
        _l.amount = _amount;
        _l.interestRate = _rate;
        _l.isCollateral = _isCollateral;
        _l.startDate = block.timestamp;
        emit LineOfCreditSet(_to, _amount, _rate);
    }

    /**
     * @dev function to change the admin/loandContract
     * @param _admin address of new admin
     * @param _collateralContract address of new loan contract
     */
    function updateSystemVariables(address _admin, address _collateralContract, address _feeContract, address _treasury, uint256 _fee, uint256 _collateralDiscount) external{
        require(msg.sender == admin);
        require(_treasury != address(0));
        proposalTime = block.timestamp;
        proposedAdmin = _admin;
        proposedCollateralContract = _collateralContract;
        proposedFeeContract = _feeContract;
        proposedTreasury = _treasury;
        proposedFee = _fee;
        proposedCollateralDiscount = _collateralDiscount;
        emit SystemUpdateProposal(_admin,_collateralContract,_feeContract,_treasury,_fee,_collateralDiscount);
    }
    
    /**
     * @dev function to take out a loan once approved
     * @param _to address of person taking out loan
     * @param _amount amount of loan to take out (fee included in this amount)
     */
    function withdrawLoan(address _to, uint256 _amount) external{
        require(msg.sender == admin || msg.sender == _to);
        LineOfCredit storage _l  = linesOfCredit[_to];
        require(block.timestamp >= _l.startDate + 1 days);
        uint256 _interest;
        if(_l.amountTaken > 0){
            uint256 _newValue = _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000;
            _interest = _newValue - _l.amountTaken;
        }
        _l.amountTaken = _amount + _l.amountTaken + _interest;
        require(_l.amountTaken <= _l.amount);
        if(_l.isCollateral){
            uint256 _collateral = collateralContract.getCollateralBalance(_to);
            _collateral = _collateral * collateralDiscount;
            require(_l.amountTaken <= _collateral);
        }
        _l.calcDate = block.timestamp;
        uint256 _fee = _amount * fee/100000;
        emit LoanTaken(_to,_amount);
        georgies.mint(_to,_amount - _fee);
        georgies.mint(feeContract,_fee);
        if(_interest > 0){
            georgies.mint(treasury,_interest);
        }
    }

    //getters
    /**
     * @dev function to get details of a parties loans and approvals
     * @param _to address of person taking out loan
     */
    function getCreditDetails(address _to) external view returns(
        uint256 _amount,
        uint256 _amountTaken,
        uint256 _calcDate,
        uint256 _interestRate
        ){
            LineOfCredit storage _l  = linesOfCredit[_to];
            return (_l.amount, _l.amountTaken, _l.calcDate, _l.interestRate);
    }
    
    /**
     * @dev function to get details of a parties loans and approvals
     * @param _to address of person taking out loan
     */
    function getCurrentAmountTaken(address _to) external view returns(uint256 _amountTaken){
            LineOfCredit storage _l  = linesOfCredit[_to];
            return _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000;
    }

}
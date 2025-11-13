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
        uint256 amount;//amount of credit a borrower is approved for
        uint256 amountTaken;//amount taken out or outstanding
        uint256 calcDate;//last date interest was calculated
        uint256 interestRate;//interest rate on loan; 100,000 = 100%
        uint256 startDate;
        bool isCollateral;
    }

    address public admin;//admin of the system, can change feeContract, treasury, repay loans (default), approve loans, and change fee
    address public feeContract;//address that accumulates system fees
    address public treasury;//address that gets interest accumulation of georgies (to balance system)
    address[] public borrowers;//list of borrowers all time
    ICollateral public collateralContract;
    IGeorgies public  georgies;//address of base georgies token
    uint256 constant public YEAR = 86400*365;
    uint256 public collateralDiscount;
    uint256 public fee; //fee paid on minting and burning of georgies; 100,000 = 100%  
    mapping(address => LineOfCredit) public linesOfCredit;

    //events
    event AdminChanged(address _newAdmin);
    event CollateralDiscountChanged(uint256 _newCollateralDiscount);
    event FeeChanged(uint256 _newFee);
    event FeeContractChanged(address _newFeeContract);
    event LineOfCreditSet(address _to, uint256 _amount, uint256 _rate);
    event LoanPayment(address _borrower, uint256 _amount);
    event LoanTaken(address _to, uint256 _amount);
    event TreasuryAddressChanged(address _newTreasury);

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
     * @dev function for the admin to change the fee contract
     * @param _newFeeContract address of new fee contract
     */
    function changeFeeContract(address _newFeeContract) external{
        require(msg.sender == admin);
        require(_newFeeContract != address(0));
        feeContract = _newFeeContract;
        emit FeeContractChanged(_newFeeContract);
    }

    /**
     * @dev function for the admin to change or initialize the treasury
     * @param _newTreasury address of new treasury contract
     */
    function changeTreasury(address _newTreasury) external{
        require(msg.sender == admin);
        treasury = _newTreasury;
        emit TreasuryAddressChanged(_newTreasury);
    }

    /**
     * @dev function to pay back a loan once taken out
     * @param _borrower address of person paying back loan
     * @param _amount amount of loan to pay back (fee included in this amount)
     */
    function payLoan(address _borrower, uint256 _amount) external{
        require(msg.sender == _borrower || msg.sender == admin, "must be authorized");
        LineOfCredit storage _l  = linesOfCredit[_borrower];
        require(_l.amountTaken > 0);
        uint256 _currentValue =  _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000; 
        uint256 _interest = _currentValue - _l.amountTaken;
        uint256 _fee;
        uint256 _paymentAmount;
        georgies.mint(treasury,_interest);
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
        if(_l.amount == 0){
            borrowers.push(_to);
        }
        _l.amount = _amount;
        _l.interestRate = _rate;
        _l.isCollateral = _isCollateral;
        _l.startDate = block.timestamp;
        emit LineOfCreditSet(_to, _amount, _rate);
    }

    /**
     * @dev function for admin to set a collateralDiscount
     * @param _collateralDiscount 1 = 1 to 1 ratio
     */
    function setCollateralDiscount(uint256 _collateralDiscount) external{
        require(msg.sender == admin);
        collateralDiscount = _collateralDiscount;
        emit CollateralDiscountChanged(_collateralDiscount);
    }

    /**
     * @dev function for admin to set the fee in the system
     * @param _fee new fee rate; 100,000 = 100%
     */
    function setFee(uint256 _fee) external{
        require(_fee < 5000);//sanity check, must be less than 5%
        require(msg.sender == admin);
        fee = _fee;
        emit FeeChanged(_fee);
    }


    function borrowViaCollateral(address _to, uint256 _amount) external{
        require(msg.sender == admin || msg.sender == _to);
        uint256 _collateral = collateralContract.getCollateralBalance(_to);
        _collateral = _collateral * collateralDiscount;
        LineOfCredit storage _l  = linesOfCredit[_to];
        require(block.timestamp > _l.startDate + 1 days);
        require(_l.isCollateral);
        uint256 _interest;
        if(_l.amountTaken > 0){
            uint256 _newValue = _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000;
            require(_newValue <= _collateral);
            _interest = _newValue - _l.amountTaken;
            georgies.mint(treasury,_interest);
        }
        _l.amountTaken = _amount + _l.amountTaken + _interest;
        require(_l.amountTaken <= _l.amount);
        require(_l.amountTaken <= _collateral);
        _l.calcDate = block.timestamp;
        uint256 _fee = _amount * fee/100000;
        emit LoanTaken(_to,_amount);
        georgies.mint(_to,_amount - _fee);
        georgies.mint(feeContract,_fee);
    }

    function payOffCollateralLoan(address _borrower, uint256 _amount) external{
        uint256 _collateral = collateralContract.getCollateralBalance(_borrower);
        uint256 _adjCollateral = _collateral * collateralDiscount;
        LineOfCredit storage _l  = linesOfCredit[_borrower];
        require(_l.amountTaken > 0);
        uint256 _currentValue =  _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000; 
        if(_currentValue <= _adjCollateral){
            require(msg.sender == _borrower || msg.sender == admin, "must be authorized");
        }
        else{
            if(_currentValue >= _collateral){
                _currentValue = _collateral;
            }
        }
        uint256 _interest = _currentValue - _l.amountTaken;
        uint256 _fee;
        uint256 _paymentAmount;
        georgies.mint(treasury,_interest);
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
        collateralContract.sendCollateral(msg.sender, _paymentAmount);
        _l.amountTaken = _currentValue - _paymentAmount;
        _l.calcDate = block.timestamp;
        emit LoanPayment(_borrower,_amount);
    }

    /**
     * @dev function to take out a loan once approved
     * @param _to address of person taking out loan
     * @param _amount amount of loan to take out (fee included in this amount)
     */
    function withdrawLoan(address _to, uint256 _amount) external{
        require(msg.sender == admin || msg.sender == _to);
        LineOfCredit storage _l  = linesOfCredit[_to];
        require(block.timestamp > _l.startDate + 1 days);
        uint256 _interest;
        if(_l.amountTaken > 0){
            uint256 _newValue = _l.amountTaken + _l.amountTaken* _l.interestRate * 100000 * (block.timestamp - _l.calcDate)/YEAR/100000/100000;
            _interest = _newValue - _l.amountTaken;
            georgies.mint(treasury,_interest);
        }
        _l.amountTaken = _amount + _l.amountTaken + _interest;
        require(_l.amountTaken <= _l.amount);
        _l.calcDate = block.timestamp;
        uint256 _fee = _amount * fee/100000;
        emit LoanTaken(_to,_amount);
        georgies.mint(_to,_amount - _fee);
        georgies.mint(feeContract,_fee);
    }   

    //getters
    /**
     * @dev function to get details of a parties loans and approvals
     * @param _to address of person taking out loan
     */
    function getCreditDetails(address _to) external view returns(
        uint256 amount,
        uint256 _amountTaken,
        uint256 _calcDate,
        uint256 _interestRate
        ){
            LineOfCredit storage _l  = linesOfCredit[_to];
            return (_l.amount, _l.amountTaken, _l.calcDate, _l.interestRate);
    }

}
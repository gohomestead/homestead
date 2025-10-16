// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IGeorgies.sol";

contract LoanOriginator {
    //storage
    address public admin;
    address public feeContract;
    address public treasury;
    address[] public borrowers;
    IGeorgies public  georgies;
    uint256 constant public YEAR = 86400*365;
    uint256 public fee; //100,000 = 100%  
    mapping(address => LineOfCredit) public linesOfCredit;

    struct LineOfCredit {
        uint256 amount;
        uint256 amountTaken;
        uint256 calcDate;
        uint256 interestRate;
    }

    //events
    event AdminChanged(address _newAdmin);
    event FeeChanged(uint256 _newFee);
    event FeeContractChanged(address _newFeeContract);
    event LineOfCreditSet(address _to, uint256 _amount, uint256 _rate);
    event LoanPayment(address _borrower, uint256 _amount);
    event LoanTaken(address _to, uint256 _amount);
    event TreasuryAddressChanged(address _newTreasury);

    //functions
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

    function changeFeeContract(address _newFeeContract) external{
        require(msg.sender == admin);
        require(_newFeeContract != address(0));
        feeContract = _newFeeContract;
        emit FeeContractChanged(_newFeeContract);
    }

    function changeTreasury(address _newTreasury) external{
        require(msg.sender == admin);
        treasury = _newTreasury;
        emit TreasuryAddressChanged(_newTreasury);
    }

    function setLineOfCredit(address _to, uint256 _amount, uint256 _rate) external{
        require(msg.sender == admin);
        LineOfCredit storage _l  = linesOfCredit[_to];
        //require(_l.amountTaken == 0);//change? 
        _l.amount = _amount;
        _l.interestRate = _rate;
        borrowers.push(_to);
        emit LineOfCreditSet(_to, _amount, _rate);
    }

    function setFee(uint256 _fee) external{
        require(msg.sender == admin);
        fee = _fee;
        emit FeeChanged(_fee);
    }


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

    function withdrawLoan(address _to, uint256 _amount) external{
        require(msg.sender == admin || msg.sender == _to);
        LineOfCredit storage _l  = linesOfCredit[_to];
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
        georgies.mint(_to,_amount);
        georgies.mint(feeContract,_fee);
    }   

    //getters
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
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IGeorgies.sol";

contract LoanOriginator {
    address public feeContract;
    IGeorgies georgies;
    address public admin;
    uint256 public fee; //100,000 = 100%
    mapping(address => LineOfCredit) public linesOfCredit;
    address[] public borrowers;
    uint256 constant public YEAR = 86400*365;

    struct LineOfCredit {
        uint256 amount;
        uint256 interestRate;
        uint256 amountTaken;
        uint256 calcDate;
        bool revoked;
    }

    event LoanPayment(address _borrower, uint256 _amount);
    event FeeChanged(uint256 _newFee);
    event LineOfCreditIssued(address _to, uint256 _amount, uint256 _rate);
    event LineOfCreditRevoked(address _borrower);
    event LoanTaken(address _to, uint256 _amount);

    constructor(address _feeContract, address _georgies, address _admin){
        feeContract = _feeContract;
        georgies = IGeorgies(_georgies);
        admin = _admin;
    }

    function setFee(uint256 _fee) external{
        require(msg.sender == admin);
        fee = _fee;
        emit FeeChanged(_fee);
    }


    function issueLineOfCredit(address _to, uint256 _amount, uint256 _rate) external{
        require(msg.sender == admin);
        LineOfCredit storage _l  = linesOfCredit[_to];
        _l.amount = _amount;
        _l.interestRate = _rate;
        emit LineOfCreditIssued(_to, _amount, _rate);
    }

    function revokeLineOfCredit(address _borrower) external{
        require(msg.sender == admin);
        LineOfCredit storage  _l  = linesOfCredit[_borrower];
        _l.revoked = true;
        emit LineOfCreditRevoked(_borrower);
    }

    function withdrawLoan(address _to, uint256 _amount) external{
        require(msg.sender == admin || msg.sender == _to);
        LineOfCredit storage _l  = linesOfCredit[_to];
        require(!_l.revoked);
        uint256 _totalOut = _amount;
        if(_l.amountTaken > 0){
            uint256 _currentValue = _l.amountTaken * (100000 + _l.interestRate) * (block.timestamp - _l.calcDate)/YEAR / 100000; 
            _totalOut += _currentValue;
        }
        require(_totalOut < _l.amount);
        _l.amountTaken = _totalOut;
        _l.calcDate = block.timestamp;
        uint256 _fee = _amount * fee/100000;
        emit LoanTaken(_to,_amount);
        georgies.mint(_to,_amount);
        georgies.mint(feeContract,_fee);
    }      

    function payLoan(address _borrower, uint256 _amount) external{
        require(msg.sender == _borrower || msg.sender == admin);
        LineOfCredit storage _l  = linesOfCredit[_borrower];
        uint256 _currentValue = _l.amountTaken * (100000 + _l.interestRate) * (block.timestamp - _l.calcDate)/YEAR / 100000;
        //takeOutFee
        if(_amount > _currentValue + _currentValue * fee/100000){
            _amount = _currentValue + _currentValue * fee/100000;
        }
        uint256 _fee = _amount * fee/100000;
        uint256 _paymentAmount = _amount -_fee;
        georgies.transferFrom(msg.sender,feeContract,_fee);
        georgies.burn(msg.sender,_paymentAmount);
        _l.amountTaken = _currentValue - _paymentAmount;
        _l.calcDate = block.timestamp;
        emit LoanPayment(_borrower,_amount);
    }
}
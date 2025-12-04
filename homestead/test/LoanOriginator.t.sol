// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { LoanOriginator } from "../src/LoanOriginator.sol";
import { Collateral } from "../src/Collateral.sol";
import {TestToken } from "../src/test/TestToken.sol";

contract LoanOriginatorTest is Test {
    LoanOriginator public loanO;
    TestToken public georgies;
    TestToken public token;
    Collateral public collateral;
    address _a1;
    address _a2;
    address _a3;
    address _a4;
    uint256 constant public YEAR = 86400*365;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        _a3 = vm.addr(3);
        _a4 = vm.addr(4);
        georgies = new TestToken("Test","tst");
        loanO = new LoanOriginator(_a2,address(georgies),_a1);
        token = new TestToken("testCollateral","tst");
        collateral = new Collateral(address(token),address(loanO),_a1);
        token.mint(_a4,100 ether);
        vm.prank(_a1);
        loanO.init(address(collateral),_a3,250,90000);
    }

    function test_ConstructorAndInit() public{
        assertEq(address(loanO.admin()),_a1);
        assertEq(address(loanO.feeContract()),_a2);
        assertEq(address(loanO.treasury()),_a3);
        assertEq(address(loanO.georgies()),address(georgies));
        assertEq(loanO.fee(),250);
        assertEq(address(loanO.collateralContract()),address(collateral));
        assertEq(loanO.collateralDiscount(),90000);
        vm.expectRevert();
        loanO.init(_a4,_a3,250,80000);
    }

    function test_SetLineOfCredit() public{
        address _a5 = vm.addr(5);
        vm.expectRevert();
        loanO.setLineOfCredit(_a5,10 ether,2000,false);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000,false);
        (uint256 amount,,,uint256 interestRate) = loanO.getCreditDetails(_a5);
        assertEq(amount,10 ether);
        assertEq(interestRate,2000);
        assertEq(georgies.balanceOf(_a5),0);
    }
    function test_UpdateSystemVariablesAndFinalizeUpdate() public{
        address _a5 = vm.addr(5);
        address _a6 = vm.addr(6);
        address _a7 = vm.addr(7);
        address _a8 = vm.addr(8);
        vm.expectRevert();
        loanO.updateSystemVariables(_a5,_a6,_a7,_a8,500,800000);
        vm.prank(_a1);
        vm.expectRevert();
        loanO.updateSystemVariables(_a5,_a6,_a7,address(0),500,800000);
        vm.prank(_a1);
        loanO.updateSystemVariables(_a5,_a6,_a7,_a8,500,800000);
        assertEq(loanO.proposalTime(), block.timestamp);
        assertEq(loanO.proposedAdmin(),_a5);
        assertEq(loanO.proposedCollateralContract(),_a6);
        assertEq(loanO.proposedFeeContract(),_a7);
        assertEq(loanO.proposedTreasury(),_a8);
        assertEq(loanO.proposedFee(),500);
        assertEq(loanO.proposedCollateralDiscount(),800000);
        vm.prank(_a1);
        vm.expectRevert();
        loanO.finalizeUpdate();
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        loanO.finalizeUpdate();
        assertEq(loanO.admin(),_a5);
        assertEq(address(loanO.feeContract()),_a7);
        assertEq(address(loanO.collateralContract()),_a6);
        assertEq(address(loanO.treasury()),_a8);
        assertEq(loanO.fee(),500);
        assertEq(loanO.collateralDiscount(),800000);
    }
    function test_PayLoanAndGetCreditDetailsAndGetCurrentAmountTaken() public{
        address _a5 = vm.addr(5);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000,false);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        loanO.withdrawLoan(_a5,10 ether);
        vm.warp(block.timestamp + YEAR);
        uint256 _currentValue = 10 ether * 102 / 100;
        assertEq(loanO.getCurrentAmountTaken(_a5),_currentValue);
        vm.expectRevert();
        loanO.payLoan(_a5,1 ether);
        vm.expectRevert();
        vm.prank(_a5);
        loanO.payLoan(_a5,1 ether);
        vm.prank(_a5);
        georgies.approve(address(loanO),1 ether);
        vm.prank(_a5);
        loanO.payLoan(_a5,1 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a5);
        assertEq(amount,10 ether);
        uint256 _fee = 1 ether * 250/100000;
        uint256 _paymentAmount = 1 ether -_fee;
        assertEq(amountTaken, _currentValue - _paymentAmount);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a5),9 ether - 10 ether * .0025);
        assertEq(georgies.balanceOf(_a2),.0025 * 11 ether);
        assertEq(loanO.getCurrentAmountTaken(_a5),_currentValue - _paymentAmount);
    }


    function test_WithdrawLoan() public{ 
        address _a5 = vm.addr(5);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000,false);
        vm.expectRevert();
        loanO.withdrawLoan(_a5,5 ether);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        loanO.withdrawLoan(_a5,5 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a5);
        uint256 fee = .0025 * 5 ether;
        assertEq(amount,10 ether);
        assertEq(amountTaken, 5 ether);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a5),5 ether - fee);
        assertEq(georgies.balanceOf(_a2),fee);
    }

    function test_withdrawViaCollateral() public{ 
        address _a5 = vm.addr(5);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000,true);
        token.mint(_a5,100 ether);
        vm.expectRevert();
        loanO.withdrawLoan(_a5,5 ether);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a5);
        vm.expectRevert();
        loanO.withdrawLoan(_a5, 5 ether);
        vm.prank(_a5);
        token.approve(address(collateral), 50 ether);
        vm.prank(_a5);
        collateral.depositCollateral(50 ether);
        vm.prank(_a5);
        loanO.withdrawLoan(_a5, 5 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a5);
        uint256 fee = .0025 * 5 ether;
        assertEq(amount,10 ether);
        assertEq(amountTaken, 5 ether);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a5),5 ether - fee);
        assertEq(georgies.balanceOf(_a2),fee);
    }

    function test_payOffCollateralLoanl() public{ 
        address _a5 = vm.addr(5);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000,true);
        token.mint(_a5,100 ether);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a5);
        token.approve(address(collateral), 50 ether);
        vm.prank(_a5);
        collateral.depositCollateral(50 ether);
        vm.prank(_a5);
        loanO.withdrawLoan(_a5, 10 ether);
        vm.warp(block.timestamp + YEAR);
        uint256 _currentValue = 10 ether * 102 / 100;
        assertEq(loanO.getCurrentAmountTaken(_a5),_currentValue);
        vm.expectRevert();
        loanO.payLoan(_a5,1 ether);
        vm.expectRevert();
        vm.prank(_a5);
        loanO.payLoan(_a5,1 ether);
        vm.prank(_a5);
        georgies.approve(address(loanO),1 ether);
        vm.prank(_a5);
        loanO.payLoan(_a5,1 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a5);
        assertEq(amount,10 ether);
        uint256 _fee = 1 ether * 250/100000;
        uint256 _paymentAmount = 1 ether -_fee;
        assertEq(amountTaken, _currentValue - _paymentAmount);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a5),9 ether - 10 ether * .0025);
        assertEq(georgies.balanceOf(_a2),.0025 * 11 ether);
        assertEq(loanO.getCurrentAmountTaken(_a5),_currentValue - _paymentAmount);
        assertEq(collateral.getCollateralBalance(_a5), 50 ether);
    }
}

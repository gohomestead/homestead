// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { LoanOriginator } from "../src/LoanOriginator.sol";
import {TestToken } from "../src/test/TestToken.sol";

contract LoanOriginatorTest is Test {
    LoanOriginator public loanO;
    TestToken public georgies;
    address _a1;
    address _a2;
    address _a3;
    uint256 constant public YEAR = 86400*365;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        _a3 = vm.addr(3);
        georgies = new TestToken("Test","tst");
        loanO = new LoanOriginator(_a2,address(georgies),_a1);
        vm.prank(_a1);
        loanO.changeTreasury(_a3);
        vm.prank(_a1);
        loanO.setFee(250);
    }

    function test_ConstructorAndAdminChanges() public{
        assertEq(address(loanO.admin()),_a1);
        assertEq(address(loanO.feeContract()),_a2);
        assertEq(address(loanO.treasury()),_a3);
        assertEq(address(loanO.georgies()),address(georgies));
        vm.expectRevert();
        loanO.changeFeeContract(_a2);
        vm.prank(_a1);
        loanO.changeFeeContract(_a2);
        assertEq(loanO.feeContract(),_a2);
        vm.expectRevert();
        loanO.changeTreasury(_a2);
        vm.prank(_a1);
        loanO.changeTreasury(_a2);
        assertEq(loanO.treasury(),_a2);
        vm.expectRevert();
        loanO.changeAdmin(_a2);
        vm.prank(_a1);
        loanO.changeAdmin(_a2);
        assertEq(loanO.admin(),_a2);
    }

    function test_SetLineOfCredit() public{
        address _a4 = vm.addr(4);
        vm.expectRevert();
        loanO.setLineOfCredit(_a4,10 ether,2000);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000);
        (uint256 amount,,,uint256 interestRate) = loanO.getCreditDetails(_a4);
        assertEq(loanO.borrowers(0),_a4);
        assertEq(amount,10 ether);
        assertEq(interestRate,2000);
        assertEq(georgies.balanceOf(_a4),0);

    }
    function test_SetFee() public{
        vm.expectRevert();
        loanO.setFee(1000);
        vm.prank(_a1);
        loanO.setFee(1000);
        assertEq(loanO.fee(),1000);
    }
    function test_PayLoan() public{
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,10 ether);
        vm.warp(block.timestamp + YEAR);
        vm.expectRevert();
        loanO.payLoan(_a4,1 ether);
        vm.expectRevert();
        vm.prank(_a4);
        loanO.payLoan(_a4,1 ether);
        vm.prank(_a4);
        georgies.approve(address(loanO),1 ether);
        vm.prank(_a4);
        loanO.payLoan(_a4,1 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a4);
        assertEq(amount,10 ether);
        uint256 _currentValue = 10 ether * 102 / 100;
        uint256 _fee = 1 ether * 250/100000;
        uint256 _paymentAmount = 1 ether -_fee;
        assertEq(amountTaken, _currentValue - _paymentAmount);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a4),9 ether - 10 ether * .0025);
        assertEq(georgies.balanceOf(_a2),.0025 * 11 ether);
    }

    function test_WithdrawLoan() public{ 
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000);
        vm.expectRevert();
        loanO.withdrawLoan(_a4,5 ether);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,5 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a4);
        uint256 fee = .0025 * 5 ether;
        assertEq(amount,10 ether);
        assertEq(amountTaken, 5 ether);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a4),5 ether - fee);
        assertEq(georgies.balanceOf(_a2),fee);
    }
}

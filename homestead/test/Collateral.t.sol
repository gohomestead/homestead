// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Collateral } from "../src/Collateral.sol";
import {TestToken } from "../src/test/TestToken.sol";
import { LoanOriginator } from "../src/LoanOriginator.sol";

contract CollateralTest is Test {
    TestToken public token;
    Collateral public collateral;
    LoanOriginator public loanO;
    address _a1;
    address _a2;
    address _a3;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        _a3 = vm.addr(3);
        token = new TestToken("testG","tst");
        loanO = new LoanOriginator(_a2,address(token),_a1);
        collateral = new Collateral(address(token),address(loanO),_a1);
        token.mint(_a3,100 ether);
    }

    function test_ConstructorAndUpdateSystemVariables() public{
        assertEq(address(collateral.admin()),_a1);
        assertEq(address(collateral.loanContract()),address(loanO));
        assertEq(address(collateral.collateralToken()),address(token));
        address _a4 = vm.addr(4);
        vm.expectRevert();
        collateral.updateSystemVariables(_a3,_a4);
        vm.prank(_a1);
        collateral.updateSystemVariables(_a3,_a4);
        assertEq(address(collateral.loanContract()),address(loanO));
        assertEq(address(collateral.admin()),_a1);
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        collateral.finalizeUpdate();
        assertEq(address(collateral.loanContract()),_a4);
        assertEq(address(collateral.admin()),_a3);
    }

    function test_depositCollateral() public{
        vm.prank(_a3);
        vm.expectRevert();
        collateral.depositCollateral(50 ether);
        vm.prank(_a3);
        token.approve(address(collateral), 50 ether);
        vm.prank(_a3);
        collateral.depositCollateral(50 ether);
        assertEq(collateral.totalCollateral(),50 ether);
        assertEq(collateral.getCollateralBalance(_a3),50 ether);
        assertEq(token.balanceOf(_a3),50 ether);
    }

    function test_reddemCollateral() public{
        vm.prank(_a3);
        token.approve(address(collateral), 50 ether);
        vm.prank(_a3);
        collateral.depositCollateral(50 ether);
        vm.prank(_a3);
        collateral.redeemCollateral(20 ether);
        assertEq(collateral.totalCollateral(),30 ether);
        assertEq(collateral.getCollateralBalance(_a3),30 ether);
        assertEq(token.balanceOf(_a3),70 ether);
        assertEq(token.balanceOf(address(collateral)),30 ether);
    }

    function test_sendCollateral() public{
        address _a4 = vm.addr(4);
        vm.prank(_a3);
        token.approve(address(collateral), 50 ether);
        vm.prank(_a3);
        collateral.depositCollateral(50 ether);
        vm.prank(_a1);
        collateral.updateSystemVariables(_a3,_a4);
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        collateral.finalizeUpdate();
        vm.prank(_a2);
        vm.expectRevert();
        collateral.sendCollateral(_a3,_a2,50 ether);
        vm.prank(_a4);
        collateral.sendCollateral(_a3,_a2,50 ether);
        assertEq(collateral.totalCollateral(),0);
        assertEq(collateral.getCollateralBalance(_a3),0);
        assertEq(token.balanceOf(_a3),50 ether);
        assertEq(token.balanceOf(_a2),50 ether);
        assertEq(token.balanceOf(address(collateral)),0);
    }
}

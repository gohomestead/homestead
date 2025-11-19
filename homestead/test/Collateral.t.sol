// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Collateral } from "../src/Collateral.sol";
import {TestToken } from "../src/test/TestToken.sol";

contract CollateralTest is Test {
    TestToken public token;
    Collateral public collateral;
    address _a1;
    address _a2;
    address _a3;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        _a3 = vm.addr(3);
        token = new TestToken("testG","tst");
        collateral = new Collateral(address(token),_a2,_a1);
        token.mint(_a3,100 ether);
    }

    function test_ConstructorAndUpdateSystemVariables() public{
        assertEq(address(collateral.admin()),_a1);
        assertEq(address(collateral.loanContract()),_a2);
        assertEq(address(collateral.collateralToken()),address(token));
        address _a4 = vm.addr(4);
        vm.expectRevert();
        collateral.updateSystemVariables(_a3,_a4);
        vm.prank(_a1);
        collateral.updateSystemVariables(_a3,_a4);
        assertEq(address(collateral.loanContract()),_a2);
        assertEq(address(collateral.admin()),_a1);
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        collateral.finalizeUpdate();
        assertEq(address(collateral.loanContract()),_a4);
        assertEq(address(collateral.admin()),_a3);
    }

    // function test_depositCollateral() public{

    // }

    // function test_reddemCollateral() public{

    // }

    // function testGetCollateralBalance() public{

    // }

    // function test_sendCollateral() public{
    //     assertEq(treasury.totalOut(),0);
    //     collateral.mint(address(treasury),100 ether);
    //     vm.expectRevert();
    //     treasury.doMonetaryPolicy(_a2,10 ether);
    //     vm.prank(_a1);
    //     treasury.doMonetaryPolicy(_a2,5 ether);
    //     assertEq(treasury.totalOut(),5 ether);
    //     assertEq(treasury.getFundsByAddress(_a2), 5 ether);
    //     assertEq(collateral.balanceOf(_a2),5 ether);
    //     assertEq(collateral.balanceOf(address(treasury)),95 ether);
    // }
}

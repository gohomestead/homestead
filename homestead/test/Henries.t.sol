// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Henries } from "../src/Henries.sol";

contract HenriesTest is Test {
    Henries public henries;
    address _a1;
    address _a2;
    address _a3;
    address _a4; 

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        _a3 = vm.addr(3);
        _a4 = vm.addr(4);
        henries = new Henries(_a1,100 ether,"testG","tst");
        vm.expectRevert();
        henries.init(_a3,_a4);
        vm.prank(_a1);
        henries.init(_a3,_a4);
    }

    function test_ConstructorAndInit() public{
        vm.prank(_a1);
        vm.expectRevert();
        henries.init(_a1,_a2);
        assertEq(address(henries.admin()),_a1);
        assertEq(henries.totalSupply(), 100 ether);
        assertEq(henries.balanceOf(_a1), 100 ether);
        assertEq(henries.feeContract(),_a3);
        assertEq(henries.stakingContract(), _a4);
    }

    function test_UpdateSystemVariablesAndFinalizeUpdate() public{
        address _a5 = vm.addr(5);
        address _a6 = vm.addr(6);
        address _a7 = vm.addr(7);
        vm.expectRevert();
        henries.updateSystemVariables(_a5,_a6,_a7);
        vm.prank(_a1);
        vm.expectRevert();
        henries.updateSystemVariables(_a5,address(0),_a7);
        vm.prank(_a1);
        henries.updateSystemVariables(_a5,_a6,_a7);
        assertEq(henries.proposalTime(), block.timestamp);
        assertEq(henries.proposedAdmin(),_a5);
        assertEq(henries.proposedFeeContract(),_a6);
        assertEq(henries.proposedStakingContract(),_a7);
        vm.prank(_a1);
        vm.expectRevert();
        henries.finalizeUpdate();
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        henries.finalizeUpdate();
        assertEq(henries.admin(),_a5);
        assertEq(henries.feeContract(),_a6);
        assertEq(henries.stakingContract(),_a7);
    }

    function test_MintAndBurn() public{
        vm.expectRevert();
        henries.mint(100 ether);
        vm.prank(_a1);
        henries.mint(100 ether);
        assertEq(henries.totalSupply(),200 ether);
        assertEq(henries.balanceOf(_a4),99 ether);
        assertEq(henries.balanceOf(_a1),101 ether);
        vm.expectRevert();
        henries.burn(_a4,10 ether);
        vm.prank(_a3);
        henries.burn(_a4,30 ether);
        assertEq(henries.balanceOf(_a4),69 ether);
        assertEq(henries.balanceOf(_a1),101 ether);
        assertEq(henries.totalSupply(),170 ether);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Georgies } from "../src/Georgies.sol";

contract GeorgiesTest is Test {
    Georgies public georgies;
    address _a1;
    address _a2;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        georgies = new Georgies(_a1,"testG","tst");
        vm.prank(_a1);
        georgies.init(_a2);
    }

    function test_ConstructorAndUpdateSystemVariables() public{
        assertEq(address(georgies.admin()),_a1);
        address _a3 = vm.addr(3);
        address _a4 = vm.addr(4);
        vm.expectRevert();
        georgies.updateSystemVariables(_a3,_a4);
        vm.prank(_a1);
        georgies.updateSystemVariables(_a3,_a4);
        assertEq(georgies.loanContract(),_a2);
        assertEq(georgies.admin(),_a1);
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        georgies.finalizeUpdate();
        assertEq(georgies.loanContract(),_a4);
        assertEq(georgies.admin(),_a3);
    }

    function test_mint() public{
        vm.expectRevert();
        georgies.mint(_a1,2 ether);
        vm.prank(_a2);
        georgies.mint(_a2, 3 ether);
        assertEq(georgies.balanceOf(_a2),3 ether);
        assertEq(georgies.balanceOf(_a1),0);
    }
    
    function test_burn() public{
        vm.prank(_a2);
        georgies.mint(_a2, 3 ether);
        vm.expectRevert();
        georgies.burn(_a2,2 ether);
        vm.startPrank(_a2);
        vm.expectRevert();
        georgies.burn(_a1,2 ether);
        georgies.burn(_a2,2 ether);
        assertEq(georgies.balanceOf(_a2),1 ether);
        assertEq(georgies.balanceOf(_a1),0);
    }

    function test_blacklistUpdateand_moveAndBlacklistUserAndIsBlacklisted() public{
        address _a3 = vm.addr(3);
        address _a4 = vm.addr(4);
        address _a5 = vm.addr(5);
        address[] memory _t = new address[](2);
        bool[] memory _b = new bool[](2);
        vm.prank(_a2);
        georgies.mint(_a3, 3 ether);
        vm.prank(_a3);
        georgies.transfer(_a4,1 ether);
        _t[0] = _a4; 
        _b[0] = true;
        vm.expectRevert();
        georgies.blacklistUpdate(_t,_b);
        assertEq(georgies.isBlacklisted(_a4),false);
        vm.prank(_a1);
        georgies.blacklistUpdate(_t,_b);
        assertEq(georgies.isBlacklisted(_a4),true);
        vm.prank(_a4);
        vm.expectRevert();
        georgies.transfer(_a2,1 ether);
        vm.prank(_a3);
        vm.expectRevert();
        georgies.transfer(_a4,1 ether);
        vm.prank(_a1);
        _t[0] = _a4;
        _t[1] = _a3;
        _b[0] = false;
        _b[1] = true;
        georgies.blacklistUpdate(_t,_b);
        assertEq(georgies.isBlacklisted(_a4),false);
        vm.prank(_a4);
        georgies.transfer(_a2,1 ether);
        vm.prank(_a3);
        vm.expectRevert();
        georgies.transfer(_a4,1 ether);
        assertEq(georgies.balanceOf(_a3),2 ether);
        assertEq(georgies.balanceOf(_a4),0);
        assertEq(georgies.balanceOf(_a2),1 ether);
        vm.expectRevert();
        georgies.blacklistUser(_a5,true);
        assertEq(georgies.isBlacklisted(_a5),false);
        vm.prank(_a1);
        georgies.blacklistUser(_a5,true);
        assertEq(georgies.isBlacklisted(_a5),true);
    }

}

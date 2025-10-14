// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Henries } from "../src/Henries.sol";

contract HenriesTest is Test {
    Henries public henries;
    address _a1;
    address _a2;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        henries = new Henries(_a1,100 ether,"testG","tst");
    }

    function test_ConstructorAndChangeFeeContractAndChangeAdmin() public{
        assertEq(address(henries.admin()),_a1);
        assertEq(henries.totalSupply(), 100 ether);
        assertEq(henries.balanceOf(_a1), 100 ether);
        vm.expectRevert();
        henries.changeFeeContract(_a2);
        vm.prank(_a1);
        henries.changeFeeContract(_a2);
        assertEq(henries.feeContract(),_a2);
        vm.expectRevert();
        henries.changeAdmin(_a2);
        vm.prank(_a1);
        henries.changeAdmin(_a2);
        assertEq(henries.admin(),_a2);
    }


    function test_MintAndBurn() public{
        address _a3 = vm.addr(3);
        address[] memory _t = new address[](1);
        uint[] memory _b = new uint[](1);
        _t[0] = _a3;
        _b[0] = 100 ether;
        vm.expectRevert();
        henries.mint(_t,_b);
        vm.prank(_a1);
        henries.changeFeeContract(_a2);
        vm.prank(_a1);
        henries.mint(_t,_b);
        assertEq(henries.totalSupply(),201 ether);
        assertEq(henries.balanceOf(_a3),100 ether);
        assertEq(henries.balanceOf(_a1),101 ether);
        vm.expectRevert();
        henries.burn(_a3,10 ether);
        vm.prank(_a2);
        henries.burn(_a3,30 ether);
        assertEq(henries.balanceOf(_a3),70 ether);
        assertEq(henries.balanceOf(_a1),101 ether);
        assertEq(henries.totalSupply(),171 ether);
    }
}

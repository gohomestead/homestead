// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Treasury } from "../src/Treasury.sol";
import {TestToken } from "../src/test/TestToken.sol";

contract GeorgiesTest is Test {
    TestToken public georgies;
    Treasury public  treasury;
    address _a1;
    address _a2;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        georgies = new TestToken("testG","tst");
        treasury = new Treasury(_a1, address(georgies));
    }

    function test_ConstructorAndChangeAdmin() public{
        assertEq(address(treasury.admin()),_a1);
        assertEq(address(treasury.georgies()),address(georgies));
        vm.expectRevert();
        treasury.changeAdmin(_a2);
        vm.prank(_a1);
        treasury.changeAdmin(_a2);
        assertEq(treasury.admin(),_a2);
    }

    function test_doMonetaryPolicy() public{
        assertEq(treasury.totalOut(),0);
        georgies.mint(address(treasury),100 ether);
        vm.expectRevert();
        treasury.doMonetaryPolicy(_a2,10 ether);
        vm.prank(_a1);
        treasury.doMonetaryPolicy(_a2,5 ether);
        assertEq(treasury.totalOut(),5 ether);
        assertEq(treasury.getFundsByAddress(_a2), 5 ether);
        assertEq(georgies.balanceOf(_a2),5 ether);
        assertEq(georgies.balanceOf(address(treasury)),95 ether);
    }
}

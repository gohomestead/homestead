// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "../forge-std/src/Test.sol";
import {TestToken } from "../src/test/TestToken.sol";

contract TokenTest is Test {
    TestToken public token;

    function setUp() public {
        token = new TestToken("test","tst");
    }

    function test_Constructor() public view{
        assertEq(token.decimals(), 18);
        assertEq(token.name(), "test");
        assertEq(token.symbol(),"tst");
    }

    function test_ApproveAndAllowanceAndMint() public{
        address _a1 = vm.addr(1);
        address _a2 = vm.addr(2);
        vm.startPrank(_a1);
        token.mint(_a1,2 ether);
        assertEq(token.balanceOf(_a1), 2 ether);
        token.approve(_a2,1 ether);
        assertEq(token.allowance(_a1,_a2), 1 ether);
    }

    function test_TransferAndBalanceOf() public{
        address _a1 = vm.addr(1);
        address _a2 = vm.addr(2);
        vm.startPrank(_a1);
        token.mint(_a1,6 ether);
        token.transfer(_a2,1 ether);
        assertEq(token.balanceOf(_a1), 5 ether);
        assertEq(token.balanceOf(_a2), 1 ether);
        token.approve(_a2,1 ether);
        assertEq(token.allowance(_a1,_a2), 1 ether);
    }

    function test_TransferFromAndMove() public{
        address _a1 = vm.addr(1);
        address _a2 = vm.addr(2);
        address _a3 = vm.addr(3);
        token.mint(_a1,10 ether);
        vm.prank(_a1);
        token.approve(_a2,1 ether);
        vm.prank(_a2);
        token.transferFrom(_a1,_a3,1 ether);
        assertEq(token.balanceOf(_a1), 9 ether);
        assertEq(token.balanceOf(_a2), 0);
        assertEq(token.balanceOf(_a3), 1 ether);
    }

    function test_TotalSupplyAndBurn() public{
        address _a1 = vm.addr(1);
        token.mint(_a1,100 ether);
        assertEq(token.totalSupply(), 100 ether);
        vm.prank(_a1);
        token.burn(_a1,5 ether);
        assertEq(token.balanceOf(_a1), 95 ether);
        assertEq(token.totalSupply(), 95 ether);
    }
}

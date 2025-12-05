// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { StakingContract } from "../src/StakingContract.sol";
import {TestToken } from "../src/test/TestToken.sol";

contract StakingContractTest is Test {
    TestToken public henries;
    TestToken public georgies;
    StakingContract public  staking;
    address _a1;
    address _a2;
    address _a3;

    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        _a3 = vm.addr(3);
        henries = new TestToken("testG","tst");
        georgies = new TestToken("testG","tst");
        staking = new StakingContract(address(georgies),address(henries),"stakingContractToken","sct");
        georgies.mint(_a3,100 ether);
        henries.mint(_a2, 100 ether);
    }

    function test_ConstructorAndSystemVariables() public view{
        assertEq(address(staking.henries()),address(henries));
        assertEq(address(staking.georgies()),address(georgies));
    }

    function test_stake() public{
        vm.prank(_a3);
        vm.expectRevert();
        staking.stake(30 ether);
        vm.prank(_a3);
        georgies.approve(address(staking),30 ether);
        vm.prank(_a3);
        staking.stake(30 ether);
        vm.prank(_a3);
        assertEq(staking.balanceOf(_a3),30 ether);
        assertEq(georgies.balanceOf(_a3),70 ether);
    }

    function test_unstake() public{
        vm.prank(_a3);
        georgies.approve(address(staking),30 ether);
        vm.prank(_a3);
        staking.stake(30 ether);
        vm.prank(_a1);
        vm.expectRevert();
        staking.unstake(20 ether);
        vm.prank(_a3);
        vm.expectRevert();
        staking.unstake(40 ether);
        vm.prank(_a2);
        henries.transfer(address(staking),20 ether);
        vm.prank(_a3);
        staking.unstake(15 ether);
        assertEq(staking.totalSupply(),15 ether);
        assertEq(staking.balanceOf(_a3),15 ether);
        assertEq(georgies.balanceOf(_a3),85 ether);
        assertEq(henries.balanceOf(_a3),10 ether);
    }
}

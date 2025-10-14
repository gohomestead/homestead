// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/src/Test.sol";
import { TestToken } from "../src/test/TestToken.sol";
import { Henries } from "../src/Henries.sol";
import { FeeContract } from "../src/FeeContract.sol";

contract FeeContractTest is Test {
    TestToken public georgies;
    Henries public henries;
    FeeContract public feeContract;
    address _a1;

    function setUp() public {
        _a1 = vm.addr(1);
        georgies = new TestToken("testG","tst");
        henries = new Henries(_a1, 100 ether, "testH","tst");
        feeContract = new FeeContract(address(henries),address(georgies),7 days);
        vm.prank(_a1);
        henries.changeFeeContract(address(feeContract));
    }

    function test_ConstructorAndInit() public view{
        assertEq(address(feeContract.henries()),address(henries));
        assertEq(address(feeContract.georgies()), address(georgies));
        assertEq(feeContract.auctionFrequency(), 86400*7);
        assert(feeContract.endDate() > block.timestamp);
    }

    function test_Bid() public{
        vm.startPrank(_a1);
        vm.expectRevert();
        feeContract.bid(0);
        address _a2 = vm.addr(2);
        henries.transfer(_a2,10 ether);
        henries.approve(address(feeContract),1 ether);
        feeContract.bid(1 ether);
        assertEq(feeContract.currentTopBid(), 1 ether);
        assertEq(feeContract.topBidder(), _a1);
        assertEq(henries.balanceOf(_a1),89 ether);
        vm.stopPrank();
        vm.startPrank(_a2);
        henries.approve(address(feeContract),2 ether);
        feeContract.bid(2 ether);
        assertEq(feeContract.currentTopBid(), 2 ether);
        assertEq(feeContract.topBidder(), _a2);
        assertEq(henries.balanceOf(_a1),90 ether);
        assertEq(henries.balanceOf(_a2),8 ether);
    }

    function test_startNewAuction() public{
        vm.startPrank(_a1);
        georgies.mint(address(feeContract),2 ether);
        henries.approve(address(feeContract),1 ether);
        feeContract.bid(1 ether);
        vm.warp(feeContract.endDate() + 1);
        feeContract.startNewAuction();
        assertEq(henries.balanceOf(_a1),99 ether);
        assertEq(henries.totalSupply(),99 ether);
        assertEq(feeContract.currentTopBid(),0);
        assertEq(feeContract.topBidder(), _a1);
        assert(feeContract.endDate() >  block.timestamp);
        assertEq(georgies.balanceOf(_a1),2 ether);
        assertEq(georgies.balanceOf(address(feeContract)),0);
    }
}

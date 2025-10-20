// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Henries } from "../src/Henries.sol";
import { FeeContract } from "../src/FeeContract.sol";
import { Georgies } from "../src/Georgies.sol";
import { LoanOriginator } from "../src/LoanOriginator.sol";
import { Treasury } from "../src/Treasury.sol";
import { TestToken } from "../src/test/TestToken.sol";

contract E2ETest is Test {
    address _a1;
    address _a2;
    TestToken public usdc;
    Treasury public treasury;
    LoanOriginator public loanO;
    Georgies public georgies;
    FeeContract public feeContract;
    Henries public henries;
    uint256 constant public YEAR = 86400*365;
    uint256 constant public MONTH = 86400*30;


    function setUp() public {
        _a1 = vm.addr(1);
        _a2 = vm.addr(2);
        usdc = new TestToken("usd coin","usdc");
        georgies = new Georgies(_a1,"testG","tst");
        henries = new Henries(_a1, 100 ether, "testH","tst");
        feeContract = new FeeContract(address(henries),address(georgies),7 days);
        loanO = new LoanOriginator(address(feeContract),address(georgies),_a1);
        treasury = new Treasury(_a1, address(georgies));
        vm.prank(_a1);
        loanO.changeTreasury(address(treasury));
        vm.prank(_a1);
        loanO.setFee(250);
        vm.prank(_a1);
        henries.changeFeeContract(address(feeContract));
        vm.prank(_a1);
        georgies.changeLoanContract(address(loanO));

    }

    //Take out a new loan and then pay it off
    function test_NewLoanLifeCycle() public{
        address _a5 = vm.addr(5);
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,10 ether);
        vm.prank(_a5);
        loanO.withdrawLoan(_a5,10 ether);
        vm.prank(_a5);
        georgies.transfer(_a4,1 ether);
        for(uint i=0;i<11;i++){
            vm.warp(block.timestamp + MONTH);
            vm.prank(_a4);
            georgies.approve(address(loanO),1 ether);
            vm.prank(_a4);
            loanO.payLoan(_a4,1 ether);
        }
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a4);
        assertEq(amount,10 ether);
        assertEq(amountTaken,0);
        assertEq(calcDate,block.timestamp);
        assert(georgies.balanceOf(_a4) > 0.8 ether);
        assert(georgies.balanceOf(_a4) < 1 ether);
        assert(georgies.balanceOf(address(treasury))>.05 ether);
        assert(georgies.balanceOf(address(feeContract))>.075 ether);
        assert(georgies.balanceOf(address(feeContract))<.0753 ether);
    }
    //Blacklist a user who already has a loan out
    function test_BlacklistCurrentUser() public{
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,10 ether);
        vm.prank(_a1);
        georgies.blacklistUser(_a4,true);
        vm.prank(_a4);
        vm.expectRevert();
        georgies.transfer(_a1,1 ether);
    }

    //Mint new tokens to new holder
    function test_MintNewTokensToHolders() public{
        address _a5 = vm.addr(5);
        address _a4 = vm.addr(4);
        address _a6 = vm.addr(6);
        address _a7 = vm.addr(7);
        address _a8 = vm.addr(8);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a6,10 ether,2000);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,10 ether);
        vm.prank(_a5);
        loanO.withdrawLoan(_a5,10 ether);
        vm.prank(_a6);
        loanO.withdrawLoan(_a6,10 ether);
        vm.prank(_a4);
        georgies.transfer(_a7,10 ether);
        vm.prank(_a5);
        georgies.transfer(_a7,10 ether);
        vm.prank(_a6);
        georgies.transfer(_a8,10 ether);
        address[] memory _t = new address[](2);
        uint[] memory _b = new uint[](2);
        _t[0] = _a7;
        _t[1] =  _a8;
        _b[0] = 10 ether;
        _b[1] = 5 ether;
        vm.prank(_a1);
        henries.mint(_t,_b);
        assertEq(henries.totalSupply(),115.15 ether);
        assertEq(henries.balanceOf(_a7),10 ether);
        assertEq(henries.balanceOf(_a1),100.15 ether);
        assertEq(henries.balanceOf(_a8),5 ether);
    }
    // //Realistic Scenario - 10 loans, 10 months of paymnets
    // function test_BlacklistCurrentUser() public view{
    //     assertEq(token.decimals(), 18);
    //     assertEq(token.name(), "test");
    //     assertEq(token.symbol(),"tst");
    // }
    // //Test arb - instant issue and payback
    // function test_InstantIssueAndPayback() public view{
    //     assertEq(token.decimals(), 18);
    //     assertEq(token.name(), "test");
    //     assertEq(token.symbol(),"tst");
    // }
    // //Change Fee part way through new loans
    // function test_ChangingFee() public view{
    //     assertEq(token.decimals(), 18);
    //     assertEq(token.name(), "test");
    //     assertEq(token.symbol(),"tst");
    // }
    // //Have a default - admin pays back loan
    // function test_DefaultOnLoan() public view{
    //     assertEq(token.decimals(), 18);
    //     assertEq(token.name(), "test");
    //     assertEq(token.symbol(),"tst");
    // }

}

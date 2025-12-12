// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { Henries } from "../src/Henries.sol";
import { FeeContract } from "../src/FeeContract.sol";
import { Georgies } from "../src/Georgies.sol";
import { LoanOriginator } from "../src/LoanOriginator.sol";
import { Treasury } from "../src/Treasury.sol";
import { TestToken } from "../src/test/TestToken.sol";
import { StakingContract } from "../src/test/StakingContract.sol";
import { Collateral } from "../src/Collateral.sol";

contract E2ETest is Test {
    address _a1;
    address _a2;
    TestToken public usdc;
    Treasury public treasury;
    LoanOriginator public loanO;
    Georgies public georgies;
    FeeContract public feeContract;
    Collateral public collateral;
    StakingContract public staking;
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
        staking = new StakingContract(address(georgies),address(henries),"stakingContractToken","sct");
        collateral = new Collateral(address(usdc),address(loanO),_a1);
        vm.prank(_a1);
        henries.init(address(feeContract),address(staking));
        vm.prank(_a1);
        loanO.init(address(collateral),address(treasury),250,900000);
        vm.prank(_a1);
        georgies.init(address(loanO));

    }

    //Take out a new loan and then pay it off
    function test_NewLoanLifeCycle() public{
        address _a5 = vm.addr(5);
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000,false);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,10 ether,2000,false);
        vm.warp(block.timestamp + 1 days);
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
        loanO.setLineOfCredit(_a4,10 ether,2000,false);
        vm.warp(block.timestamp + 1 days);
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
                 uint256 loanA = uint256(4000000000000000000000) / 399;
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,loanA,2000,false);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,loanA,2000,false);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a6,loanA,2000,false);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,loanA);
        vm.prank(_a5);
        loanO.withdrawLoan(_a5,loanA);
        vm.prank(_a6);
        loanO.withdrawLoan(_a6,loanA);
        vm.prank(_a4);
        georgies.transfer(_a7,10 ether);
        vm.prank(_a5);
        georgies.transfer(_a7,10 ether);
        vm.prank(_a6);
        georgies.transfer(_a8,10 ether);
        vm.prank(_a7);
        georgies.approve(address(staking),20 ether);
        vm.prank(_a8);
        georgies.approve(address(staking),10 ether);
        vm.prank(_a7);
        staking.stake(20 ether);
        vm.prank(_a8);
        staking.stake(10 ether);
        vm.prank(_a1);
        henries.mint(15 ether);
        vm.prank(_a7);
        staking.unstake(20 ether);
        vm.prank(_a8);
        staking.unstake(10 ether);
        assertEq(henries.totalSupply(),115 ether);
        assert(10 ether * 99/100 - henries.balanceOf(_a7) < .001 ether);
        assertEq(henries.balanceOf(_a1),100.15 ether);
        assert(henries.balanceOf(_a8) - 5 ether * 99/100 < .0001 ether);
    }
    // //Realistic Scenario - 10 loans, 10 months of paymnets
    function test_RealisticScenario() public{
        address[] memory _addys = new address[](10);
        address _bank = vm.addr(15);
        uint256 loanA = uint256(4000000000000000000000) / 399;//10 eth + mint fee
        for(uint i=0;i<10;i++){
            _addys[i] = vm.addr(i + 3);
            vm.prank(_a1);
            loanO.setLineOfCredit(_addys[i],loanA,2000,false);
            vm.prank(_addys[i]);
            vm.warp(block.timestamp + 1 days);
            loanO.withdrawLoan(_addys[i],loanA);
            vm.prank(_addys[i]);
            georgies.transfer(_bank,10 ether);
        }
        assertEq(georgies.totalSupply(),loanA * 10);
        //do auction
        vm.prank(_a1);
        henries.approve(address(feeContract),1 ether);
        feeContract.startNewAuction();
        vm.prank(_a1);
        feeContract.bid(1 ether);
        vm.warp(feeContract.endDate() + 1);
                vm.prank(_a1);
        feeContract.startNewAuction();
        assertEq(georgies.balanceOf(address(feeContract)),0);
        uint _bal;
        uint _tbal;
        uint256 _taken;
        for(uint j=0;j<10;j++){
            vm.warp(block.timestamp + MONTH);
                for(uint i=0;i<9;i++){
                    _bal= georgies.balanceOf(address(treasury));
                    _tbal += _bal;
                    if(_bal > 0){
                        vm.prank(_a1);
                        treasury.doMonetaryPolicy(_bank, _bal);
                    }
                    if(j == 9){
                        (,_taken,,) = loanO.getCreditDetails(_addys[i]);
                        vm.prank(_bank);
                        georgies.transfer(_addys[i],_taken + .1 ether);
                        vm.prank(_addys[i]);
                        georgies.approve(address(loanO),_taken + .1 ether);
                        vm.prank(_addys[i]);
                        loanO.payLoan(_addys[i],_taken + .1 ether);
                    }else{
                        vm.prank(_bank);
                        georgies.transfer(_addys[i],1 ether);
                        vm.prank(_addys[i]);
                        georgies.approve(address(loanO),1 ether);
                        vm.prank(_addys[i]);
                        loanO.payLoan(_addys[i],1 ether);
                    }
                }
        }
        for(uint i=0;i<9;i++){
            (uint256 amount,
            uint256 amountTaken,
            uint256 calcDate,) = loanO.getCreditDetails(_addys[i]);
            assertEq(amount,loanA);
            assertEq(amountTaken,0);
            assertEq(calcDate,block.timestamp);
            assert(georgies.balanceOf(_addys[i]) < .1 ether);
        }
        assert(_tbal + georgies.balanceOf(address(treasury)) > .5 ether);//rough interest rate guess
        assert(_tbal + georgies.balanceOf(address(treasury)) < 1 ether);
        assert(georgies.balanceOf(address(feeContract))>.0025 * 10 ether * 9);
        assert(georgies.balanceOf(address(feeContract))<.0025 * 10 ether * 10);
        assertEq(henries.balanceOf(_a1),99 ether);
        assertEq(henries.totalSupply(),99 ether);
        assertEq(feeContract.currentTopBid(),0);
        assertEq(feeContract.topBidder(), _a1);
        (,_taken,,) = loanO.getCreditDetails(_addys[9]);
        assertEq(georgies.totalSupply(), _taken);
    }
    //Test arb - instant issue and payback
    function test_InstantIssueAndPayback() public{
        vm.prank(_a1);
        loanO.setLineOfCredit(_a1,20 ether,2000,false);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        uint256 loanA = uint256(4000000000000000000000) / 399;
        loanO.withdrawLoan(_a1,loanA);
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        georgies.transfer(_a4, 1 ether);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,10 ether,2000,false);
        vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,10 ether);
        vm.prank(_a4);
        georgies.approve(address(loanO),10 ether);
        vm.prank(_a4);
        loanO.payLoan(_a4,10 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a4);
        assertEq(amount,10 ether);
        uint256 _currentValue = 10 ether;
        uint256 _fee = 10 ether * 250/100000;
        uint256 _paymentAmount = 10 ether -_fee;
        assertEq(amountTaken, _currentValue - _paymentAmount);
        assertEq(calcDate,block.timestamp);
        assertEq(georgies.balanceOf(_a4),1 ether - _fee);
        assert(georgies.balanceOf(address(feeContract))>.0075 ether);
        assert(georgies.balanceOf(address(feeContract))<.0751 ether);
    }

    //Change Fee part way through new loans
    function test_ChangingFee() public{
        address[] memory _addys = new address[](10);
        address _bank = vm.addr(15);
        uint256 loanA = uint256(4000000000000000000000) / 399;//10 eth + mint fee
        for(uint i=0;i<10;i++){
            _addys[i] = vm.addr(i + 3);
            vm.prank(_a1);
            loanO.setLineOfCredit(_addys[i],loanA,2000,false);
            vm.warp(block.timestamp + 1 days);
            vm.prank(_addys[i]);
            loanO.withdrawLoan(_addys[i],loanA);
            vm.prank(_addys[i]);
            georgies.transfer(_bank,10 ether);
        }
        uint256 _totalFees = georgies.balanceOf(address(feeContract));
        assertEq(georgies.totalSupply(), loanA * 10);
        uint _bal;
        uint _tbal;
        for(uint j=0;j<5;j++){
            vm.warp(block.timestamp + MONTH);
                for(uint i=0;i<10;i++){
                    _bal= georgies.balanceOf(address(treasury));
                    _tbal += _bal;
                    if(_bal > 0){
                        vm.prank(_a1);
                        treasury.doMonetaryPolicy(_bank, _bal);
                    }
                    vm.prank(_bank);
                    georgies.transfer(_addys[i],1 ether);
                    vm.prank(_addys[i]);
                    georgies.approve(address(loanO),1 ether);
                    vm.prank(_addys[i]);
                    loanO.payLoan(_addys[i],1 ether);
                }
        }
        uint256 payFees = georgies.balanceOf(address(feeContract)) - _totalFees;
        _totalFees = georgies.balanceOf(address(feeContract));
        //changeFee
        vm.prank(_a1);
        loanO.updateSystemVariables(_a1,address(collateral),address(feeContract), address(treasury),1000,900000);
        vm.warp(block.timestamp + 86401*7);
        vm.prank(_a1);
        loanO.finalizeUpdate();
        assertEq(loanO.fee(),1000);
        for(uint j=5;j<10;j++){
            if(j==5){
                vm.warp(block.timestamp + MONTH - 86401*7);
            }
            else{
                vm.warp(block.timestamp + MONTH);
            }
                for(uint i=0;i<9;i++){
                    _bal= georgies.balanceOf(address(treasury));
                    _tbal += _bal;
                    if(_bal > 0){
                        vm.prank(_a1);
                        treasury.doMonetaryPolicy(_bank, _bal);
                    }
                    if(j == 9){
                        (,uint256 _taken,,) = loanO.getCreditDetails(_addys[i]);
                        vm.prank(_bank);
                        georgies.transfer(_addys[i],_taken + .1 ether);
                        vm.prank(_addys[i]);
                        georgies.approve(address(loanO),_taken + .1 ether);
                        vm.prank(_addys[i]);
                        loanO.payLoan(_addys[i],_taken + .1 ether);
                    }else{
                        vm.prank(_bank);
                        georgies.transfer(_addys[i],1 ether);
                        vm.prank(_addys[i]);
                        georgies.approve(address(loanO),1 ether);
                        vm.prank(_addys[i]);
                        loanO.payLoan(_addys[i],1 ether);
                    }
                }
        }
        uint256 payFees2 = georgies.balanceOf(address(feeContract)) - _totalFees;
        for(uint i=0;i<9;i++){
            (uint256 amount,
            uint256 amountTaken,
            uint256 calcDate,) = loanO.getCreditDetails(_addys[i]);
            assertEq(amount,loanA);
            assertEq(amountTaken,0);
            assertEq(calcDate,block.timestamp);
            assert(georgies.balanceOf(_addys[i]) < .1 ether);
        }
        uint256 _res =  5 * 9 * .01 ether + 5 * 10 * .0025 ether + 10 * 10.025 * .0025 ether;
        _res = _res;
        assert(georgies.balanceOf(address(feeContract)) - _res < .05 ether);
        _res = 5 * 10 * .0025 ether;
        assert(payFees == _res);
        _res =  5* 9 * .01 ether + _tbal * 1000/100000;
        assert(payFees2 - _res < .01 ether);
    }
    // //Have a default - admin pays back loan
    function test_DefaultOnLoan() public{
        address _a5 = vm.addr(5);
        address _a4 = vm.addr(4);
        address _a6 = vm.addr(6);
        address _a7 = vm.addr(7);
        uint256 loanA = uint256(4000000000000000000000) / 399;//10 eth + mint fee
        vm.prank(_a1);
        loanO.setLineOfCredit(_a1,20 ether,2000,false);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a4,20 ether,2000,false);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a5,20 ether,2000,false);
                vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        loanO.withdrawLoan(_a1,loanA);
        vm.prank(_a1);
        loanO.withdrawLoan(_a4,loanA);
        vm.prank(_a5);
        loanO.withdrawLoan(_a5,loanA);
        vm.prank(_a4);
        georgies.transfer(_a6,10 ether);
        vm.prank(_a5);
        georgies.transfer(_a7,10 ether);
        uint totalFees = .0025 * 30 ether;
        for(uint i=0;i<3;i++){
            vm.warp(block.timestamp + MONTH);
            vm.prank(_a6);
            georgies.transfer(_a4,1 ether);
            vm.prank(_a7);
            georgies.transfer(_a5,1 ether);
            vm.prank(_a4);
            georgies.approve(address(loanO),1 ether);
            vm.prank(_a4);
            loanO.payLoan(_a4,1 ether);
            totalFees += .0025 * 1 ether;
            vm.prank(_a5);
            georgies.approve(address(loanO),1 ether);
            vm.prank(_a5);
            loanO.payLoan(_a5,1 ether);
            totalFees += .0025 * 1 ether;
        }
        //default on a4 loan
        vm.prank(_a1);
        georgies.approve(address(loanO),7.1 ether);
        totalFees += .0025 * 7.1 ether;
        vm.prank(_a1);
        loanO.payLoan(_a4,7.1 ether);
        (uint256 amount,
        uint256 amountTaken,
        uint256 calcDate,) = loanO.getCreditDetails(_a4);
        assertEq(amount,20 ether);
        assertEq(amountTaken,0);
        assertEq(calcDate,block.timestamp);
        assert(georgies.balanceOf(_a4) == 0 ether);
        assert(georgies.balanceOf(address(treasury))>.05 ether);
        //fees = 
        assert(georgies.balanceOf(address(feeContract))> .107 ether);
        assert(georgies.balanceOf(address(feeContract))<.1079 ether);
    }

        function test_blacklistedAuctionWinner() public{
        address _a4 = vm.addr(4);
        vm.prank(_a1);
        loanO.setLineOfCredit(_a1,20 ether,2000,false);
                vm.warp(block.timestamp + 1 days);
        vm.prank(_a1);
        loanO.withdrawLoan(_a1,10 ether);
        vm.prank(_a1);
        georgies.transfer(address(feeContract), 5 ether);
        uint256 ibal = georgies.balanceOf(address(feeContract));
        vm.prank(_a1);
        henries.transfer(_a4,1 ether);
        vm.prank(_a4);
        henries.approve(address(feeContract),1 ether);
        vm.prank(_a4);
        feeContract.bid(1 ether);
        vm.prank(_a1);
        georgies.blacklistUser(_a4,true);
        vm.warp(feeContract.endDate() + 1);
        vm.prank(_a1);
        feeContract.startNewAuction();
        assertEq(feeContract.currentTopBid(),1 ether);
        assertEq(feeContract.topBidder(), _a1);
        assert(feeContract.endDate() >  block.timestamp);
        assertEq(georgies.balanceOf(_a4),0);
        assertEq(georgies.balanceOf(address(feeContract)),ibal);
        assertEq(henries.balanceOf(address(feeContract)),1 ether);
    }
    // function test_defaultOnCollateralLoan() public{
    //             address _a6 = vm.addr(6);
    //             vm.prank(_a1);
    //             loanO.setLineOfCredit(_a6,20 ether,2000,false);
    //             vm.warp(block.timestamp + 1 days);
    //     vm.prank(_a6);
    //     loanO.withdrawLoan(_a6,10 ether);
    //     address _a5 = vm.addr(5);
    //     vm.prank(_a1);
    //     loanO.setLineOfCredit(_a5,10 ether,2000,true);
    //     token.mint(_a5,100 ether);
    //     vm.warp(block.timestamp + 1 days);
    //     vm.prank(_a5);
    //     token.approve(address(collateral), 20 ether);
    //     vm.prank(_a5);
    //     collateral.depositCollateral(20 ether);
    //     vm.prank(_a5);
    //     loanO.withdrawLoan(_a5, 10 ether); //needs 10 /.9 collateral for loan.  
    //     vm.warp(block.timestamp + YEAR); // in 2 years, needs 10*1.02^2
    //     uint256 _currentValue = 10 ether * 102 / 100;
    //     assertEq(loanO.getCurrentAmountTaken(_a5),_currentValue);
    //     vm.expectRevert();
    //     loanO.payLoan(_a5,1 ether);
    //     vm.prank(_a5);
    //     georgies.approve(address(loanO),1 ether);
    //     vm.prank(_a5);
    //     loanO.payLoan(_a5,1 ether);
    //     //now fast forward with no payments
    //     vm.warp(block.timestamp + YEAR);
    //     //another party closes it out. 
    //     vm.prank(_a6);
    //     loanO.payLoan();//pays it all off
    //     //should get collateral
    //     (uint256 amount,
    //     uint256 amountTaken,
    //     uint256 calcDate,) = loanO.getCreditDetails(_a5);
    //     assertEq(amount,10 ether);
    //     uint256 _fee = 1 ether * 250/100000;
    //     uint256 _paymentAmount = 1 ether -_fee;
    //     assertEq(amountTaken, _currentValue - _paymentAmount);
    //     assertEq(calcDate,block.timestamp);
    //     assertEq(georgies.balanceOf(_a5),9 ether - 10 ether * .0025);
    //     assertEq(georgies.balanceOf(_a2),.0025 * 11 ether);
    //     assertEq(loanO.getCurrentAmountTaken(_a5),_currentValue - _paymentAmount);
    //     assertEq(collateral.getCollateralBalance(_a5), 50 ether);
    // }
}
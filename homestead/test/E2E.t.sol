// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.25;

// import {Test, console} from "forge-std/Test.sol";
// import {TestToken } from "../src/test/TestToken.sol";

// contract TokenTest is Test {
//     TestToken public token;


//     function setUp() public {
//         token = new TestToken("test","tst");
//     }

//     function test_Constructor() public view{
//         assertEq(token.decimals(), 18);
//         assertEq(token.name(), "test");
//         assertEq(token.symbol(),"tst");
//     }

//     function test_ApproveAndAllowanceAndMint() public{
//         address _a1 = vm.addr(1);
//         address _a2 = vm.addr(2);
//         vm.startPrank(_a1);
//         token.mint(_a1,2 ether);
//         assertEq(token.balanceOf(_a1), 2 ether);
//         token.approve(_a2,1 ether);
//         assertEq(token.allowance(_a1,_a2), 1 ether);
//     }

//     function test_TransferAndTransferFromAndBalanceOf() public{
//         address _a1 = vm.addr(1);
//         address _a2 = vm.addr(2);
//         vm.startPrank(_a1);
//         token.mint(_a1,2 ether);
//         assertEq(token.balanceOf(_a1), 2 ether);
//         token.approve(_a2,1 ether);
//         assertEq(token.allowance(_a1,_a2), 1 ether);
//     }

//     function test_TotalSupplyAndBurn() public{
//         address _a1 = vm.addr(1);
//         address _a2 = vm.addr(2);
//         vm.startPrank(_a1);
//         token.mint(_a1,2 ether);
//         assertEq(token.balanceOf(_a1), 2 ether);
//         token.approve(_a2,1 ether);
//         assertEq(token.allowance(_a1,_a2), 1 ether);
//     }
//     // function testFuzz_SetNumber(uint256 x) public {
//     //     counter.setNumber(x);
//     //     assertEq(counter.number(), x);
//     // }
// }

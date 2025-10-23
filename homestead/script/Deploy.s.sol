// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import { Henries } from "../src/Henries.sol";
import { FeeContract } from "../src/FeeContract.sol";
import { Georgies } from "../src/Georgies.sol";
import { LoanOriginator } from "../src/LoanOriginator.sol";
import { Treasury } from "../src/Treasury.sol";
import { TestToken } from "../src/test/TestToken.sol";

//forge script DeployScript --rpc-url $API_KEY --verify --etherscan-api-key --broadcast

contract DeployScript is Script {
    address admin;
    TestToken public usdc;
    Treasury public treasury;
    LoanOriginator public loanO;
    Georgies public georgies;
    FeeContract public feeContract;
    Henries public henries;

    function run() public {
        uint _pk = vm.envUint("PRIVATE_KEY");
        admin = vm.addr(_pk);
        console.log("My Address:", admin);
        vm.startBroadcast(_pk);

        georgies = new Georgies(admin,"Georgeies","georgies");
        console.log("Georgies: ",address(georgies));
        henries = new Henries(admin, 1000000 ether, "Henries","henries");
        console.log("Henries: ",address(henries));
        feeContract = new FeeContract(address(henries),address(georgies),7 days);
        console.log("Fee Contract: ",address(feeContract));
        loanO = new LoanOriginator(address(feeContract),address(georgies),admin);
        console.log("Loan Originator: ",address(loanO));
        treasury = new Treasury(admin, address(georgies));
        console.log("Treasury: ",address(treasury));
        loanO.changeTreasury(address(treasury));
        loanO.setFee(250);//0.25%
        henries.changeFeeContract(address(feeContract));
        georgies.changeLoanContract(address(loanO));
        vm.stopBroadcast();
    }
}
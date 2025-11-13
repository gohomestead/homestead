//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import "./Token.sol";

//          _       _    _            _             _            _          _           _        
//         / /\    / /\ /\ \         /\ \     _    /\ \         /\ \       /\ \        / /\      
//        / / /   / / //  \ \       /  \ \   /\_\ /  \ \        \ \ \     /  \ \      / /  \     
//       / /_/   / / // /\ \ \     / /\ \ \_/ / // /\ \ \       /\ \_\   / /\ \ \    / / /\ \__  
//      / /\ \__/ / // / /\ \_\   / / /\ \___/ // / /\ \_\     / /\/_/  / / /\ \_\  / / /\ \___\ 
//     / /\ \___\/ // /_/_ \/_/  / / /  \/____// / /_/ / /    / / /    / /_/_ \/_/  \ \ \ \/___/ 
//    / / /\/___/ // /____/\    / / /    / / // / /__\/ /    / / /    / /____/\      \ \ \       
//   / / /   / / // /\____\/   / / /    / / // / /_____/    / / /    / /\____\/  _    \ \ \      
//  / / /   / / // / /______  / / /    / / // / /\ \ \  ___/ / /__  / / /______ /_/\__/ / /      
// / / /   / / // / /_______\/ / /    / / // / /  \ \ \/\__\/_/___\/ / /_______\\ \/___/ /       
// \/_/    \/_/ \/__________/\/_/     \/_/ \/_/    \_\/\/_________/\/__________/ \_____\/  
/**
 @title Henries
 @dev the incentive token for the homestead protocol
**/
contract Henries is Token{

    //storage
    address public admin;//address of the admin
    address public feeContract;//address of feeContract
    address public stakingContract; //address of the stakingContract

    //events
    event AdminChanged(address _newAdmin);
    event FeeContractChanged(address _newFeeContract);
    event HenriesBurned(address _from, uint256 _amount);
    event HenriesMinted(address _to, uint256 _amount);
    event StakingContractChanged(address _newStakingContract);


    //functions
    /**
     * @dev constructor to initialize contract and token
     * must also initialize the fee contract in the system to fully start
     */
    constructor(address _admin, uint256 _initialSupply, string memory _name, string memory _symbol) Token(_name,_symbol){
        admin = _admin;
        _mint(admin, _initialSupply);
    }

    /**
     * @dev allows the fee contract to burn tokens of users
     * @param _from address to burn tokens of
     * @param _amount amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external{
        require(msg.sender == feeContract);
        _burn(_from, _amount);
        emit HenriesBurned(_from,_amount);
    }

    /**
     * @dev function to change the admin
     * @param _newAdmin address of new admin
     */
    function changeAdmin(address _newAdmin) external{
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }
    
    /**
     * @dev function for the admin to change the fee contract
     * @param _newFeeContract address of new fee contract
     */
    function changeFeeContract(address _newFeeContract) external{
        require(msg.sender == admin);
        require(_newFeeContract != address(0));
        feeContract = _newFeeContract;
        emit FeeContractChanged(_newFeeContract);
    }
    
    /**
     * @dev function for the admin to change the staking contract
     * @param _newStakingContract address of new staking contract
     */
    function changeStakingContract(address _newStakingContract) external{
        require(msg.sender == admin);
        require(_newStakingContract != address(0));
        stakingContract = _newStakingContract;
        emit StakingContractChanged(_newStakingContract);
    }

    /**
     * @dev allows the admin contract to mint henry tokens
     * @param _amount amount of tokens to mint
     */
    function mint(uint256 _amount) external{
        require(msg.sender == admin);
        _mint(stakingContract, _amount*99/100);
        _mint(admin,_amount/100);//1% of mint goes to admin
    }
}
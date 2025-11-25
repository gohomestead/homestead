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
    address public proposedAdmin;
    address public proposedFeeContract;
    address public proposedStakingContract;
    address public stakingContract; //address of the stakingContract
    uint256 public proposalTime;

    //events
    event SystemUpdateProposal(address _proposedAdmin, address feeContract, address _proposedStakingContract);
    event SystemVariablesUpdated(address _admin, address _feeContract, address _stakingContract);

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
     * @dev function to init the fee contract and staking contract
     * @param _feeContract address of fee Contract (can burn henries)
     * @param _stakingContract address of staking Contract (gets minted henries)
     */
    function init(address _feeContract, address _stakingContract) external{
        require(msg.sender == admin);
        require(feeContract == address(0));
        require(_feeContract != address(0));
        feeContract = _feeContract;
        stakingContract = _stakingContract;
    }

    /**
     * @dev allows the fee contract to burn tokens of users
     * @param _from address to burn tokens of
     * @param _amount amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external{
        require(msg.sender == feeContract);
        _burn(_from, _amount);
    }
    
    /**
     * @dev function to finalize an update after 7 days
     */
    function finalizeUpdate() external{
        require(msg.sender == admin);
        require(block.timestamp - proposalTime > 7 days);
        admin = proposedAdmin;
        feeContract = proposedFeeContract;
        stakingContract = proposedStakingContract;
        emit SystemVariablesUpdated(admin, feeContract, stakingContract);
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

    /**
     * @dev function to change the admin/loandContract
     * @param _proposedAdmin address of new admin
     * @param _proposedStakingContract address of new loan contract
     */
    function updateSystemVariables(address _proposedAdmin, address _proposedFeeContract, address _proposedStakingContract) external{
        require(msg.sender == admin);
        require(_proposedFeeContract != address(0));
        proposalTime = block.timestamp;
        proposedAdmin = _proposedAdmin;
        proposedFeeContract = _proposedFeeContract;
        proposedStakingContract = _proposedStakingContract;
        emit SystemUpdateProposal(_proposedAdmin, _proposedFeeContract, _proposedStakingContract);
    }
}
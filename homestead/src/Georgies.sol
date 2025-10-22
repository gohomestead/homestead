// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./Token.sol";


//    ___                             __ _     _                    
//   / __|    ___     ___      _ _   / _` |   (_)     ___     ___   
//  | (_ |   / -_)   / _ \    | '_|  \__, |   | |    / -_)   (_-<   
//   \___|   \___|   \___/   _|_|_   |___/   _|_|_   \___|   /__/_  
// _|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 
/**
 @title Georgies
 @dev base token of the system, represents a tokenized mortgage
 */
contract Georgies is Token{
    //storage
    address public admin;//admin, controls pause, blacklist functionality, and loanContract address
    address public loanContract;//loan contract that can mint/burn Georgies
    bool public paused;//contract can be paused
    mapping(address => bool) public blacklisted;

    //events
    event AdminChanged(address _newAdmin);
    event BlacklistStatusChanged(address _addy, bool _status);
    event ContractPauseChanged(bool _paused);
    event LoanContractChanged(address _newLoanContract);

    //functions
    /**
     * @dev starts the Georgies Token
     * @param _admin admin in the contract
     * @param _name this is the name of the token (standard ERC20)
     * @param _symbol this is the token symbol (standard ERC20)
     * must also initialize the loan contract in the system to fully start
     */
    constructor(address _admin,string memory _name, string memory _symbol) Token(_name,_symbol){
        admin = _admin;
    }

    /**
     * @dev function for the admin to blacklist update an array
     * @param _addresses addresses of users to blacklist (or unblacklist)
     * @param _set array of bool values to update addresses to (true = blacklisted)
     */
    function blacklistUpdate(address[] memory _addresses,bool[] memory _set) external{
        require(_addresses.length == _set.length);
        require(msg.sender == admin);
        for(uint _i=0;_i<_addresses.length;_i++){
            blacklisted[_addresses[_i]] = _set[_i];
            emit BlacklistStatusChanged(_addresses[_i], _set[_i]);
        }
    }

    /**
     * @dev function for the admin to update the blacklist status of a user
     * @param _addy address to blacklist (or unblacklist)
     * @param _set bool values to update address to (true = blacklisted)
     */
    function blacklistUser(address _addy,bool _set) external{
        require(msg.sender == admin);
        blacklisted[_addy] = _set;
        emit BlacklistStatusChanged(_addy, _set);
    }

    /**
     * @dev function for the loan contract to burn georgies
     * @param _from address to burn tokens from
     * @param _amount of tokens to burn
     */
    function burn(address _from,uint256 _amount) external{
        require(msg.sender == loanContract);
        _burn(_from,_amount);
    }

    /**
     * @dev function to change the admin
     * @param _newAdmin address of new admin
     */
    function changeAdmin(address _newAdmin) external{
        require(msg.sender == admin);
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }
    
    /**
     * @dev function for the admin to change the loanContract
     * @param _newLoanContract address of new loanContract
     */
    function changeLoanContract(address _newLoanContract) external{
        require(msg.sender == admin);
        loanContract = _newLoanContract;
        emit LoanContractChanged(_newLoanContract);
    }
    
    /**
     * @dev function for the loan contract to mint georgies
     * @param _to address to mint tokens to
     * @param _amount of tokens to mint
     */
    function mint(address _to,uint256 _amount) external{
        require(msg.sender == loanContract);
        _mint(_to,_amount);
    }

    /**
     * @dev function for the admin to pause the contract
     */
    function togglePause() external{
        require(msg.sender == admin);
        paused = !paused;
        emit ContractPauseChanged(paused);
    }

    /*Getters*/
    /**
     * @dev function retrieve blacklist status
     * @param _addy address of interest
     * @return bool of is blacklisted
     */
    function isBlacklisted(address _addy) external view returns(bool){
        return blacklisted[_addy];
    }

    /*Internal*/
    /** 
     * @dev overwrites token _move to add blacklist and pause restrictions
     * @param _src address of sender
     * @param _dst address of recipient
     * @param _amount amount of token to send
     */
    function _move(address _src, address _dst, uint256 _amount) internal override{
        require(!blacklisted[_src] && !blacklisted[_dst]);
        require(!paused);
        balance[_src] = balance[_src] - _amount;//will overflow if too big
        balance[_dst] = balance[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
    }
}

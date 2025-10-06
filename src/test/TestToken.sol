//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import "../Token.sol";

/**
 @title TestToken
 @dev mock token contract to allow minting and burning for testing
**/  
contract TestToken is Token{

    constructor(string memory _name, string memory _symbol) Token(_name,_symbol){
    }

    function burn(address _account, uint256 _amount) external virtual {
        _burn(_account,_amount);
    }
    
    function mint(address _account, uint256 _amount) external virtual {
        _mint(_account,_amount);
    }
}

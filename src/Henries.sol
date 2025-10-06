//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;


import "./Token.sol";

/**
 @title
 @dev the base token for the homestead protocol
**/
contract Henries is Token{

    //storage
    address public admin;//address of the admin
    address public feeContract;//address of feeContract

    //events
    event HenriesMinted(address _to, uint256 _amount);
    event HenriesBurned(address _from, uint256 _amount);

    //functions
    /**
     * @dev constructor to initialize contract and token
     */
    constructor(address _admin, address _feeContract, uint256 _initialSupply, string memory _name, string memory _symbol) Token(_name,_symbol){
        admin = _admin;
        feeContract = _feeContract;
        _mint(admin, _initialSupply);
    }

    /**
     * @dev allows the admin contract to burn tokens of users
     * @param _from address to burn tokens of
     * @param _amount amount of tokens to burn
     */
    function burnHenries(address _from, uint256 _amount) external{
        require(msg.sender == feeContract);
        _burn(_from, _amount);
        emit HenriesBurned(_from,_amount);
    }
    
    /**
     * @dev allows the admin contract to mint henry tokens
     * @param _to address to mint tokens to
     * @param _amount amount of tokens to mint
     */
     //should we update this to be less manual?
    function mintHenries(address[] memory _to, uint256[] memory _amount) external{
        require(msg.sender == admin);
        require(_to.length == _amount.length);
        uint256 _total;
        for(uint _i=0;_i<_to.length;_i++){
            _mint(_to[_i],_amount[_i]);
            _total += _amount[_i];
            emit HenriesMinted(_to[_i],_amount[_i]);
        }
        _mint(admin,_total/100);//1% of mint goes to admin
    }
}
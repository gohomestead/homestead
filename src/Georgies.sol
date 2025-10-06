// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;
import "./Token.sol";

contract Georgies is Token{
    address public loanContract;
    address public admin;
    bool public paused;
    mapping(address => bool) public blacklisted;

    event ContractPauseChanged(bool _paused);
    event BlacklistStatusChanged(address _addy, bool _status);
    event AdminChanged(address _newAdmin);
    event LoanContractChanged(address _newLoanContract);

    constructor(address _admin,string memory _name, string memory _symbol) Token(_name,_symbol){
        admin = _admin;

    }
    //add delay on this
    function changeLoanContract(address _newLoanContract) external{
        require(msg.sender == admin);
        loanContract = _newLoanContract;
        emit LoanContractChanged(_newLoanContract);
    }

    function mint(address _to,uint256 _amount) external{
        require(msg.sender == loanContract);
        _mint(_to,_amount);
    }

    function burn(address _from,uint256 _amount) external{
        require(msg.sender == loanContract);
        _burn(_from,_amount);
    }

    function init(address _loanContract) public{
        require(msg.sender == admin);
        require(loanContract == address(0));
        loanContract = _loanContract;
    }

    function togglePause() external{
        require(msg.sender == admin);
        paused = !paused;
        emit ContractPauseChanged(paused);
    }

    function changeAdmin(address _newAdmin) external{
        require(msg.sender == admin);
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    function blacklistUpdate(address[] memory _addresses,bool[] memory _set) external{
        require(_addresses.length == _set.length);
        require(msg.sender == admin);
        for(uint _i=0;_i<_addresses.length;_i++){
            blacklisted[_addresses[_i]] = _set[_i];
            emit BlacklistStatusChanged(_addresses[_i], _set[_i]);
        }
    }
    /**
     * @dev moves tokens from one address to another
     * @param _src address of sender
     * @param _dst address of recipient
     * @param _amount amount of token to send
     */
    function _move(address _src, address _dst, uint256 _amount) internal override{
        require(!blacklisted[_src] && !blacklisted[_dst]);
        balance[_src] = balance[_src] - _amount;//will overflow if too big
        balance[_dst] = balance[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
    }
}

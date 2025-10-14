// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./Henries.sol";


contract FeeContract {
    Henries public henries;//Henries Address
    IERC20 public georgies;//Georgies address
    uint256 public auctionFrequency;//auction frequency in seconds

    //bid variables
    uint256 public currentTopBid;
    uint256 public endDate;//end date of current auction round
    address public topBidder;

    //events
    event AuctionClosed(address _winner, uint256 _amount);
    event NewAuctionStarted(uint256 _endDate);
    event NewTopBid(address _bidder, uint256 _amount);


    /**
     * @dev starts the CIT token and auction (minting) mechanism
     * @param _henries token to be used 
     * @param _auctionFrequency time between auctions (e.g. 86400 = daily)
     */
    constructor(address _henries,address _georgies,uint256 _auctionFrequency){
        henries = Henries(_henries);
        georgies = IERC20(_georgies);
        auctionFrequency = _auctionFrequency;
        endDate = block.timestamp + _auctionFrequency;
        emit NewAuctionStarted(endDate);
    }

    /**
     * @dev allows a user to bid on the mintAmount of CIT tokens
     * @param _amount amount of your bid
     */
    function bid(uint256 _amount) external{
        require(block.timestamp < endDate, "auction must not be over");
        require(_amount > currentTopBid, "must be top bid");
        require(henries.transferFrom(msg.sender,address(this),_amount), "must get tokens");
        if(currentTopBid > 0){
            require(henries.transfer(topBidder,currentTopBid), "must send back tokens");
        }
        topBidder = msg.sender;
        currentTopBid = _amount;
        emit NewTopBid(msg.sender, _amount);
    }

    //add try in case they're blacklisted.  it should roll over to next auction
    /**
     * @dev pays out the winner of the auction and starts a new one
     */
    function startNewAuction() external{
        require(block.timestamp >= endDate, "auction must be over");
        if(currentTopBid > 0){
            georgies.transfer(topBidder,georgies.balanceOf(address(this)));
            henries.burn(address(this),currentTopBid);
        }
        emit AuctionClosed(topBidder, currentTopBid);
        endDate = block.timestamp + auctionFrequency; // just restart it...
        topBidder = msg.sender;
        currentTopBid = 0;
        emit NewAuctionStarted(endDate);
        emit NewTopBid(msg.sender, 0);
    }
}

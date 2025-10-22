// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./interfaces/IERC20.sol";
import "./Henries.sol";

//  _______  _______  _______   ______   ______   .__   __. .___________..______          ___       ______ .___________.
// |   ____||   ____||   ____| /      | /  __  \  |  \ |  | |           ||   _  \        /   \     /      ||           |
// |  |__   |  |__   |  |__   |  ,----'|  |  |  | |   \|  | `---|  |----`|  |_)  |      /  ^  \   |  ,----'`---|  |----`
// |   __|  |   __|  |   __|  |  |     |  |  |  | |  . `  |     |  |     |      /      /  /_\  \  |  |         |  |     
// |  |     |  |____ |  |____ |  `----.|  `--'  | |  |\   |     |  |     |  |\  \----./  _____  \ |  `----.    |  |     
// |__|     |_______||_______| \______| \______/  |__| \__|     |__|     | _| `._____/__/     \__\ \______|    |__|     
                                                                                                                     
/**
 @title FeeContract
 @dev admin contract to handle fees paid from minting and burning of Georgies
 // uses these fees to buy back and burn Henries using auctions of Georgies
 */
contract FeeContract {
    //storage
    Henries public henries;//Henries Address
    IERC20 public georgies;//Georgies address
    uint256 public auctionFrequency;//auction frequency in seconds

    //bid variables
    uint256 public currentTopBid;//current top bid (in georgies)
    uint256 public endDate;//end date of current auction round
    address public topBidder;//current top bidder in the round

    //events
    event AuctionClosed(address _winner, uint256 _amount);
    event BidderBlacklisted(address _bidder);
    event NewAuctionStarted(uint256 _endDate);
    event NewTopBid(address _bidder, uint256 _amount);

    //functions
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

    /**
     * @dev pays out the winner of the auction and starts a new one
     */
    function startNewAuction() external{
        require(block.timestamp >= endDate, "auction must be over");
        if(currentTopBid > 0){
            //if the top bidder is blacklisted, the call will fail.  it rolls over if this is the case
            try georgies.transfer(topBidder,georgies.balanceOf(address(this))){
                henries.burn(address(this),currentTopBid);
            } catch {
                emit BidderBlacklisted(topBidder);
            }
        }
        emit AuctionClosed(topBidder, currentTopBid);
        endDate = block.timestamp + auctionFrequency;
        topBidder = msg.sender;
        currentTopBid = henries.balanceOf(address(this));
        emit NewAuctionStarted(endDate);
        emit NewTopBid(msg.sender, georgies.balanceOf(address(this)));
    }
}

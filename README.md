## Homestead Protocol


//Georgies 
    - ERC20 token
    - pausable, blacklistable, mintable by address (the loan contract)
    - burnable as well


//loan contract
    - sets line of credit amount and interest rate
    - there is no default, that is up to the controller who can just go pay back the loan after selling the house or working with borrower
    - configurable delay on mint
    - take .25% fee on mint and burn (this goes to the admin contract)
    - has "bonus mint rate" -- set by Controller


// admin contract
    - burns the fees via weekly auction
    - If price of Georgies is below some threshold, allows the admin to control three variables:
        - mint rate of Henries
        - fee structure (eventually buy backs will be zero)
        - Lower bonus rate (if there is one)
        - Interest rate on new loans


//Henries
    - takes snapshot at date and then pays out a reward of Henries (claimable)
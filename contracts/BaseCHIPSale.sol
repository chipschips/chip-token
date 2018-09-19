pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract BaseCHIPSale {
    using SafeMath for uint256;

    address public owner;
    bool public paused = false;
    // The beneficiary is the future recipient of the funds
    address public beneficiary;

    // The crowdsale has a funding goal, cap, deadline, and minimum contribution
    uint public fundingGoal;
    uint public fundingCap;
    //uint public minContribution;
    bool public fundingGoalReached = false;
    bool public fundingCapReached = false;
    bool public saleClosed = false;

    // Time period of sale (UNIX timestamps)
    uint public startTime;
    uint public endTime;

    // Keeps track of the amount of wei raised
    uint public amountRaised;

    // Refund amount, should it be required
    uint public refundAmount;

    // The ratio of CHP to Ether
    uint public rate = 10000;
    uint public withdrawRate = 10000;

    // prevent certain functions from being recursively called
    bool private rentrancy_lock = false;

    // A map that tracks the amount of wei contributed by address
    mapping(address => uint256) public balanceOf;

    // Events
    event GoalReached(address _beneficiary, uint _amountRaised);
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event Pause();
    event Unpause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner,"Only the owner is allowed to call this."); 
        _; 
    }

    // Modifiers
    modifier beforeDeadline(){
        require (currentTime() < endTime, "Validation: Before endtime");
        _;
    }
    modifier afterDeadline(){
        require (currentTime() >= endTime, "Validation: After endtime"); 
        _;
    }
    modifier afterStartTime(){
        require (currentTime() >= startTime, "Validation: After starttime"); 
        _;
    }

    modifier saleNotClosed(){
        require (!saleClosed, "Sale is not yet ended"); 
        _;
    }

    modifier nonReentrant() {
        require(!rentrancy_lock, "Validation: Reentrancy");
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "You are not allowed to access this time.");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "You are not allowed to access this time.");
        _;
    }

    constructor() public{
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Owner cannot be 0 address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    /**
     * Returns the current time.
     * Useful to abstract calls to "now" for tests.
    */
    function currentTime() public view returns (uint _currentTime) {
        return block.timestamp;
    }

    /**
     * The owner can terminate the crowdsale at any time.
     */
    function terminate() external onlyOwner {
        saleClosed = true;
    }

    /**
     * The owner can update the rate (CHP to ETH).
     *
     * @param _rate  the new rate for converting CHP to ETH
     */
    function setRate(uint _rate) public onlyOwner {
        //require(_rate >= LOW_RANGE_RATE && _rate <= HIGH_RANGE_RATE);
        rate = _rate;
    }

    function setWithdrawRate(uint _rate) public onlyOwner {
        //require(_rate >= LOW_RANGE_RATE && _rate <= HIGH_RANGE_RATE);
        withdrawRate = _rate;
    }

    /**
     * The owner can unlock the fund with this function. The use-
     * case for this is when the owner decides after the deadline
     * to allow contributors to be refunded their contributions.
     * Note that the fund would be automatically unlocked if the
     * minimum funding goal were not reached.
     */
    function ownerUnlockFund() external afterDeadline onlyOwner {
        fundingGoalReached = false;
    }

    /**
     * Checks if the funding goal has been reached. If it has, then
     * the GoalReached event is triggered.
     */
    function checkFundingGoal() internal {
        if (!fundingGoalReached) {
            if (amountRaised >= fundingGoal) {
                fundingGoalReached = true;
                emit GoalReached(beneficiary, amountRaised);
            }
        }
    }

    /**
     * Checks if the funding cap has been reached. If it has, then
     * the CapReached event is triggered.
     */
    function checkFundingCap() internal {
        if (!fundingCapReached) {
            if (amountRaised >= fundingCap) {
                fundingCapReached = true;
                saleClosed = true;
                emit CapReached(beneficiary, amountRaised);
            }
        }
    }

    /**
     * These helper functions are exposed for changing the start and end time dynamically   
     */
    function changeStartTime(uint256 _startTime) external onlyOwner {startTime = _startTime;}
    function changeEndTime(uint256 _endTime) external onlyOwner {endTime = _endTime;}
}
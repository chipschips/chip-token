pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./BaseCHIPSale.sol";
import "./CHIPToken.sol";

contract CHIPSale is BaseCHIPSale {
    using SafeMath for uint256;

    // The token being sold
    CHIPToken public tokenReward;

    /**
     * Constructor for a crowdsale of CHPToken tokens.
     *
     * @param ifSuccessfulSendTo            the beneficiary of the fund
     * @param fundingGoalInEthers           the minimum goal to be reached
     * @param fundingCapInEthers            the cap (maximum) size of the fund
     * @param start                         the start time (UNIX timestamp)
     * @param end                           the end time (UNIX timestamp)
     * @param rateCHPToEther                 the conversion rate from CHP to Ether
     * @param addressOfTokenUsedAsReward    address of the token being sold
     */
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint fundingCapInEthers,
        //uint minimumContributionInWei,
        uint start,
        uint end,
        uint rateCHPToEther,
        address addressOfTokenUsedAsReward
    ) public {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this), "Beneficiary cannot be 0 address");
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this), "Token address cannot be 0 address");
        require(fundingGoalInEthers <= fundingCapInEthers, "Funding goal should be less that funding cap.");
        require(end > 0, "Endtime cannot be 0");
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        fundingCap = fundingCapInEthers * 1 ether;
        //minContribution = minimumContributionInWei;
        startTime = start;
        endTime = end; // TODO double check
        rate = rateCHPToEther;
        withdrawRate = rateCHPToEther;
        tokenReward = CHIPToken(addressOfTokenUsedAsReward);
    }

    /**
     * This fallback function is called whenever Ether is sent to the
     * smart contract. It can only be executed when the crowdsale is
     * not paused, not closed, and before the deadline has been reached.
     *
     * This function will update state variables for whether or not the
     * funding goal or cap have been reached. It also ensures that the
     * tokens are transferred to the sender, and that the correct
     * number of tokens are sent according to the current rate.
     */
    function () public payable whenNotPaused beforeDeadline afterStartTime saleNotClosed nonReentrant {
        //require(msg.value >= minContribution, "Value should be greater than minimum contribution");

        // Update the sender's balance of wei contributed and the amount raised
        uint amount = msg.value;
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = currentBalance.add(amount);
        amountRaised = amountRaised.add(amount);

        // Compute the number of tokens to be rewarded to the sender
        // Note: it's important for this calculation that both wei
        // and CHP have the same number of decimal places (18)
        uint numTokens = amount.mul(rate);

        // Transfer the tokens from the crowdsale supply to the sender
        if (tokenReward.transferFrom(tokenReward.owner(), msg.sender, numTokens)) {
            emit FundTransfer(msg.sender, amount, true);
            //contributions[msg.sender] = contributions[msg.sender].add(amount);
            // Following code is to automatically transfer ETH to beneficiary
            //uint balanceToSend = this.balance;
            //beneficiary.transfer(balanceToSend);
            //FundTransfer(beneficiary, balanceToSend, false);
            // Check if the funding goal or cap have been reached
            // TODO check impact on gas cost
            checkFundingGoal();
            checkFundingCap();
        }
        else {
            revert("Transaction Failed. Please try again later.");
        }
    }

    // Any users can call this function to send their tokens and get Ethers
    function withdrawToken(uint tokensToWithdraw) public {
        uint tokensInWei = convertToMini(tokensToWithdraw);
        require(
            tokensInWei <= tokenReward.balanceOf(msg.sender), 
            "You do not have sufficient balance to withdraw"
        );
        uint ethToGive = tokensInWei.div(withdrawRate);
        require(ethToGive <= address(this).balance, "Insufficient ethers.");
        //tokenReward.increaseApproval(address(this),tokensInWei);
        tokenReward.setAllowanceBeforeWithdrawal(msg.sender, address(this), tokensInWei);
        tokenReward.transferFrom(msg.sender, tokenReward.owner(), tokensInWei);
        msg.sender.transfer(ethToGive);
        emit FundTransfer(this.owner(), ethToGive, true);
    }

    /**
     * The owner can allocate the specified amount of tokens from the
     * crowdsale allowance to the recipient (_to).
     *
     * NOTE: be extremely careful to get the amounts correct, which
     * are in units of wei and mini-CHP. Every digit counts.
     *
     * @param _to            the recipient of the tokens
     * @param amountWei     the amount contributed in wei
     * @param amountMiniCHP the amount of tokens transferred in mini-CHP (18 decimals)
     */
    function ownerAllocateTokens(address _to, uint amountWei, uint amountMiniCHP) public
            onlyOwner nonReentrant
    {
        if (!tokenReward.transferFrom(tokenReward.owner(), _to, amountMiniCHP)) {
            revert("Transfer failed. Please check allowance");
        }
        balanceOf[_to] = balanceOf[_to].add(amountWei);
        amountRaised = amountRaised.add(amountWei);
        emit FundTransfer(_to, amountWei, true);
        checkFundingGoal();
        checkFundingCap();
    }

    /**
     * The owner can call this function to withdraw the funds that
     * have been sent to this contract for the crowdsale subject to
     * the funding goal having been reached. The funds will be sent
     * to the beneficiary specified when the crowdsale was created.
     */
    function ownerSafeWithdrawal() public onlyOwner nonReentrant {
        require(fundingGoalReached, "Check funding goal");
        uint balanceToSend = address(this).balance;
        beneficiary.transfer(balanceToSend);
        emit FundTransfer(beneficiary, balanceToSend, false);
    }

    /**
     * This function permits anybody to withdraw the funds they have
     * contributed if and only if the deadline has passed and the
     * funding goal was not reached.
     */
    function safeWithdrawal() public afterDeadline nonReentrant {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
                refundAmount = refundAmount.add(amount);
            }
        }
    }
    
    function convertToMini(uint amount) internal view returns (uint) {
        return amount * (10 ** uint(tokenReward.decimals()));
    }    
}
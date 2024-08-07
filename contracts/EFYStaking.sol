// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EFYBase.sol";

/**
 * @title Rhinostec / Contract to EfyFinance
 * @custom:security-contact dev@rhinostec.com
 */

contract EFYStaking is Ownable {
    IERC20 public efyToken;
    EFYBase public configContract;

    struct Stake {
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;
        uint256 endTime;
        uint256 lastInterestCalculationTime;
        uint256 accruedInterest;
    }

    mapping(address => Stake[]) private stakes;

    event NewStake(address indexed account);
    event UnStake(address indexed account, uint256 amount);

    constructor(address _efyToken, address _configContract) {
        efyToken = IERC20(_efyToken);
        configContract = EFYBase(_configContract);
    }

    modifier onlyEFYFinance() {
        require(msg.sender == address(efyToken), "EFYStaking: Only EFYFinance contract can call this function");
        _;
    }

    // Function to set the config contract address
    function setConfigContract(address _configContract) external onlyOwner {
        configContract = EFYBase(_configContract);
    }

    // Function to stake EFY tokens
    function stake(address _user, uint256 _amount) external onlyEFYFinance {

        // Check if the stake amount is greater than the minimum required
        require(
            _amount > configContract.getMinStakeValue(),
            "EFYStaking: Stake amount is less than the minimum required"
        );

        // Create a new stake object
        Stake memory newStake = Stake({
            amount: _amount,
            interestRate: configContract.getAnnualInterestRate(),
            startTime: block.timestamp,
            endTime: 0,
            lastInterestCalculationTime: block.timestamp,
            accruedInterest: 0
        });
        
        // Add the new stake to the stakes array
        stakes[_user].push(newStake);

        // Emit the new stake event
        emit NewStake(_user);
    }

    function unstake(address _user, uint256 stakeIndex) external onlyEFYFinance returns (uint256, uint256) {

        // Check if the user has stakes
        require(stakes[_user].length > 0, "EFYStaking: User has no stakes");

        // Check if the stake index is valid
        require(stakeIndex < stakes[_user].length, "EFYStaking: Invalid stake index");

        // Get the user's stake
        Stake storage userStake = stakes[_user][stakeIndex];

        // Check if the user has a stake
        require(userStake.amount > 0, "EFYStaking: No stake found");

        uint256 stakingDuration = block.timestamp - userStake.startTime;

        // Check if the un-stake block limit feature is enabled
        if (configContract.isUnStakeBlockLimitEnabled()) {

            // Check if the staking duration is greater than the minimum staking duration
            require(
                stakingDuration >= configContract.getMinStakingDuration(),
                "EFYStaking: Minimum staking duration is not met"
            );
        }
        
        // Calculate the accrued interest
        uint256 accruedInterest = getAccruedInterest(_user, stakeIndex);

        // Delete the stake from the stakes array
        delete stakes[_user][stakeIndex];

        // Emit the un-stake event
        emit UnStake(_user, userStake.amount);

        // Return the stake amount and accrued interest
        return (userStake.amount, accruedInterest);
    }

    // Function to calculate the accrued interest for a stake
    function getAccruedInterest(address _user, uint256 stakeIndex) private view returns (uint256) {

        // Check if the stake index is valid
        require(stakeIndex < stakes[_user].length, "EFYStaking:Invalid stake index");

        // Get the user's stake
        Stake storage userStake = stakes[_user][stakeIndex];

        // Check if the user has a stake
        if (userStake.amount == 0) {
            return 0;
        }
    
    
        uint256 stakingDuration = block.timestamp - userStake.lastInterestCalculationTime;

        // Calculate the additional interest
        uint256 additionalInterest = (
            userStake.amount * userStake.interestRate * stakingDuration) / 
            (365 days * configContract.INTEREST_RATE_SCALE());

        // Calculate the total accrued interest
        uint256 totalAccruedInterest = userStake.accruedInterest + additionalInterest;

        // Round down the total accrued interest
        return configContract.roundDown(totalAccruedInterest, 13);
    }

    function getStakes(address _user, uint256 startIndex, uint256 limit) external onlyEFYFinance view returns (
        uint256[] memory indexes, 
        uint256[] memory startTimes, 
        uint256[] memory amounts, 
        uint256[] memory interestRates,
        uint256[] memory accruedInterest) {

        uint256 stakeCount = stakes[_user].length;

        // Check if the start index is valid
        require(startIndex < stakeCount, "EFYStaking: Invalid start index");

        // Calculate the end index
        uint256 endIndex = startIndex + limit;
        if (endIndex > stakeCount) {
            endIndex = stakeCount;
        }

        uint256 resultCount = endIndex - startIndex;

        indexes = new uint256[](resultCount);
        startTimes = new uint256[](resultCount);
        amounts = new uint256[](resultCount);
        interestRates = new uint256[](resultCount);
        accruedInterest = new uint256[](resultCount);

        // Iterate over the stakes and populate the arrays
        for (uint256 i = 0; i < resultCount; i++) {
            indexes[i] = startIndex + i;
            startTimes[i] = stakes[_user][indexes[i]].startTime;
            amounts[i] = stakes[_user][indexes[i]].amount;
            interestRates[i] = stakes[_user][indexes[i]].interestRate;
            accruedInterest[i] = getAccruedInterest(_user, indexes[i]);
        }

        return (indexes, startTimes, amounts, interestRates, accruedInterest);
    }
}

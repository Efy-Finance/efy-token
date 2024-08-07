// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Rhinostec / Contract to EfyFinance
 * @custom:security-contact dev@rhinostec.com
 */

contract EFYBase is Ownable {
    uint256 public constant INTEREST_RATE_SCALE = 100000;
    uint256 public constant BURN_RATE_SCALE = 100000;

    uint256 private burnRate = 100; // based on 100.000
    uint256 private minStakingDuration = 30 days;
    uint256 private minStakeValue = 100_000_000_000_000_000_000; // 100 EFY as default
    uint256 private annualInterestRate = 22000; // 22% annual interest
    
    bool private burnOnTransferEnabled = true;
    bool private unStakeBlockLimit = true;

    mapping(address => uint256) internal _allocationPercentage;

    address[10] public adminAddresses;
    address public stakingWallet;

    event AnnualInterestRateChanged(uint256 oldRate, uint256 newRate);
    event MinStakingDurationChanged(uint256 oldDuration, uint256 newDuration);
    event MinStakeValueChanged(uint256 oldValue, uint256 newValue);
    event UnStakeBlockLimitToggled(bool enabled);
    event BurnRateChanged(uint256 oldRate, uint256 newRate);
    event BurnOnTransferToggled(bool enabled);

    constructor(address[10] memory addresses, address _owner) {
        adminAddresses = addresses;
        _allocationPercentage[addresses[0]] = 5;  // SEED_SALES
        _allocationPercentage[addresses[1]] = 5;  // PRIVATE_SALES
        _allocationPercentage[addresses[2]] = 12; // PUBLIC_SALES
        _allocationPercentage[addresses[3]] = 11; // ECOSYSTEM_DEVELOPMENT
        _allocationPercentage[addresses[4]] = 9;  // TEAM_ADDRESS
        _allocationPercentage[addresses[5]] = 6;  // ADVISORS_ADDRESS
        _allocationPercentage[addresses[6]] = 10; // MARKETING_ADDRESS
        _allocationPercentage[addresses[7]] = 30; // TREASURY_ADDRESS
        _allocationPercentage[addresses[8]] = 2;  // AIRDROP_ADDRESS
        _allocationPercentage[addresses[9]] = 10; // STAKING_ADDRESS

        _transferOwnership(_owner);
    }

    // return the administrative staking wallet address
    function getStakingWallet() external view returns (address) {
        return adminAddresses[9];
    }

    // return the treasury wallet address
    function getTreasuruyWallet() external view returns (address) {
        return adminAddresses[7];
    }

    function setBurnRate(uint256 newBurnRate) external onlyOwner {
        // Check if the new burn rate is between 0% and 3%
        require(newBurnRate <= 3000, "Burn rate must be between 0% and 3%");

        uint256 oldRate = burnRate;
        burnRate = newBurnRate;

        // Emit the burn rate changed event
        emit BurnRateChanged(oldRate, newBurnRate);
    }

    // return the burn rate
    function getBurnRate() external view returns (uint256) {
        return burnRate;
    }

    // Administrative function to set the minimum staking duration
    function setMinStakingDuration(uint256 _days) external onlyOwner {
        // Check if the minimum staking duration is greater than 30 days
        require(_days >= 30, "Minimum staking duration cannot be less than 30 days");

        uint256 oldDuration = minStakingDuration;
        minStakingDuration = _days * 1 days;

        // Emit the minimum staking duration changed event
        emit MinStakingDurationChanged(oldDuration, minStakingDuration);
    }

    // return the minimum staking duration
    function getMinStakingDuration() external view returns (uint256) {
        return minStakingDuration;
    }

    // Administrative function to set the minimum stake value
    function setMinStakeValue(uint256 _value) external onlyOwner {
        // Check if the minimum stake value is greater than 100 EFY
        require(_value > 100_000_000_000_000_000_000, "Minimum stake value cannot be less than 100 EFY");

        uint256 oldValue = minStakeValue;
        minStakeValue = _value;

        // Emit the minimum stake value changed event
        emit MinStakeValueChanged(oldValue, _value);
    }

    // return the minimum stake value
    function getMinStakeValue() external view returns (uint256) {
        return minStakeValue;
    }

    // Administrative function to set the annual interest rate
    function setAnnualInterestRate(uint256 _interestRate) external onlyOwner {
        // Check if the annual interest rate is greater than 10%
        require(_interestRate >= 10000, "Interest rate cannot be less than 10%");

        uint256 oldRate = annualInterestRate;
        annualInterestRate = _interestRate;

        // Emit the annual interest rate changed event
        emit AnnualInterestRateChanged(oldRate, annualInterestRate);
    }

    // return the annual interest rate
    function getAnnualInterestRate() external view returns (uint256) {
        return annualInterestRate;
    }

    // Administrative function to toggle the burn on transfer feature
    function toggleBurn(bool _enabled) external onlyOwner {
        burnOnTransferEnabled = _enabled;
        emit BurnOnTransferToggled(_enabled);
    }

    // return the burn on transfer feature status
    function isBurnEnabled() external view returns (bool) {
        return burnOnTransferEnabled;
    }

    // Administrative function to toggle the un-stake block limit feature
    function toggleUnStakeBlockLimit(bool _enabled) external onlyOwner {
        unStakeBlockLimit = _enabled;
        emit UnStakeBlockLimitToggled(_enabled);
    }

    // return the un-stake block limit feature status
    function isUnStakeBlockLimitEnabled() external view returns (bool) {
        return unStakeBlockLimit;
    }

    // return the allocation percentage for an account
    function getAllocationPercentage(address account) external view returns (uint256) {
        return _allocationPercentage[account];
    }

    function roundDown(uint256 value, uint256 decimals) public pure returns (uint256) {
        uint256 factor = 10 ** decimals;
        return (value / factor) * factor;
    }

    function isExemptFromFees(address account) public view returns (bool) {
        for (uint i = 0; i < adminAddresses.length; i++) {
            if (account == adminAddresses[i]) {
                return true;
            }
        }
        return false;
    }
}

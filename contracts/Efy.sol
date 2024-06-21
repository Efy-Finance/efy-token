// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Rhinostec / Contract to EfyFinance
 * @custom:security-contact dev@rhinostec.com
 */

contract EFYFinance is
    ERC20,
    ERC20Burnable,
    ERC20Capped,
    ERC20Pausable,
    ERC20Permit,
    Ownable
{
    bool internal burnOnTransferEnabled = true;
    bool internal unStakeBlockLimit = true;

    uint256 private constant INTEREST_RATE_SCALE = 100000;
    uint256 private constant BURN_RATE_SCALE = 100000;

    uint256 public burnRate = 100; // based on 100.000

    uint256 public minStakingDuration = 30 days;
    uint256 public minStakeValue = 100000000000000000000; // 100 EFY as default
    uint256 public annualInterestRate = 22000; // 22% annual interest

    mapping(address => bool) internal _freezeList;
    mapping(address => uint256) internal _allocationMinted;
    mapping(address => uint256) internal _allocationPercentage;

    struct Stake {
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;
        uint256 endTime;
        uint256 lastInterestCalculationTime;
        uint256 accruedInterest;
    }

    mapping(address => Stake[]) private stakes;

    event FrozenAccount(address indexed account, bool frozen);
    event NewStake(address indexed account);

    address private SEED_SALES;
    address private PRIVATE_SALES;
    address private PUBLIC_SALES;
    address public ECOSYSTEM_DEVELOPMENT;
    address public TEAM_ADDRESS;
    address public ADVISORS_ADDRESS;
    address public MARKETING_ADDRESS;
    address public TREASURY_ADDRESS;
    address public AIRDROP_ADDRESS;
    address public STAKING_ADDRESS;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address[10] memory addresses
    )
        ERC20(name, symbol)
        ERC20Capped(totalSupply * (10 ** decimals()))
        ERC20Permit(name)
    {
        // Get the total supply cap.
        uint256 _cap = cap();

        // Store the administrative addresses.
        SEED_SALES = addresses[0];
        PRIVATE_SALES = addresses[1];
        PUBLIC_SALES = addresses[2];
        ECOSYSTEM_DEVELOPMENT = addresses[3];
        TEAM_ADDRESS = addresses[4];
        ADVISORS_ADDRESS = addresses[5];
        MARKETING_ADDRESS = addresses[6];
        TREASURY_ADDRESS = addresses[7];
        AIRDROP_ADDRESS = addresses[8];
        STAKING_ADDRESS = addresses[9];

        // It specifies how the token will be distributed on a percentage basis.
        _allocationPercentage[SEED_SALES] = 5;
        _allocationPercentage[PRIVATE_SALES] = 5;
        _allocationPercentage[PUBLIC_SALES] = 12;
        _allocationPercentage[ECOSYSTEM_DEVELOPMENT] = 11;
        _allocationPercentage[TEAM_ADDRESS] = 9;
        _allocationPercentage[ADVISORS_ADDRESS] = 6;
        _allocationPercentage[MARKETING_ADDRESS] = 10;
        _allocationPercentage[TREASURY_ADDRESS] = 30;
        _allocationPercentage[AIRDROP_ADDRESS] = 2;
        _allocationPercentage[STAKING_ADDRESS] = 10;

        // Minting the initial supply
        unchecked {
            _allocationMinted[SEED_SALES] = 0;
            _allocationMinted[PRIVATE_SALES] = 0;

            uint256 publicSalesAmount = (_cap *
                _allocationPercentage[PUBLIC_SALES]) / 100;

            _mint(PUBLIC_SALES, publicSalesAmount);
            _allocationMinted[PUBLIC_SALES] = publicSalesAmount;

            uint256 ecosystemDevelopmentAmount = (_cap *
                _allocationPercentage[ECOSYSTEM_DEVELOPMENT]) / 100;

            _mint(ECOSYSTEM_DEVELOPMENT, ecosystemDevelopmentAmount);
            _allocationMinted[ECOSYSTEM_DEVELOPMENT] = ecosystemDevelopmentAmount;

            _allocationMinted[TEAM_ADDRESS] = 0;
            _allocationMinted[ADVISORS_ADDRESS] = 0;

            uint256 marketingAmount = (_cap *
                _allocationPercentage[MARKETING_ADDRESS]) / 100;

            _mint(MARKETING_ADDRESS, marketingAmount);
            _allocationMinted[MARKETING_ADDRESS] = marketingAmount;

            uint256 treasuryAmount = (_cap *
                _allocationPercentage[TREASURY_ADDRESS]) / 100;

            _mint(TREASURY_ADDRESS, treasuryAmount);
            _allocationMinted[TREASURY_ADDRESS] = treasuryAmount;

            uint256 airdropAmount = (_cap *
                _allocationPercentage[AIRDROP_ADDRESS]) / 100;

            _mint(AIRDROP_ADDRESS, airdropAmount);
            _allocationMinted[AIRDROP_ADDRESS] = airdropAmount;

            uint256 stakingAmount = (_cap *
                _allocationPercentage[STAKING_ADDRESS]) / 100;

            _mint(STAKING_ADDRESS, stakingAmount);
            _allocationMinted[STAKING_ADDRESS] = stakingAmount;
        }
    }

    // Make a verification before the transfer.
    // and check if account is frozen
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        require(!_freezeList[from], "Rhino: Your account is frozen");
        super._beforeTokenTransfer(from, to, amount);
    }

    // Function to transfer tokens between accounts.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 burnAmount = (amount * burnRate) / BURN_RATE_SCALE;
        uint256 transferAmount = amount;

        // Check if one of the wallets is an administrative wallet to avoid charging a transaction fee.
        bool isStaking = from == STAKING_ADDRESS || to == STAKING_ADDRESS;
        bool isSeedSales = from == SEED_SALES || to == SEED_SALES;
        bool isPrivateSales = from == PRIVATE_SALES || to == PRIVATE_SALES;
        bool isPublicSales = from == PUBLIC_SALES || to == PUBLIC_SALES;
        bool isEcosystemDevelopment = from == ECOSYSTEM_DEVELOPMENT || to == ECOSYSTEM_DEVELOPMENT;
        bool isTeamAddress = from == TEAM_ADDRESS || to == TEAM_ADDRESS;
        bool isAdvisorsAddress = from == ADVISORS_ADDRESS || to == ADVISORS_ADDRESS;
        bool isMarketingAddress = from == MARKETING_ADDRESS || to == MARKETING_ADDRESS;
        bool isTreasuryAddress = from == TREASURY_ADDRESS || to == TREASURY_ADDRESS;
        bool isAirdropAddress = from == AIRDROP_ADDRESS || to == AIRDROP_ADDRESS;

        // If one of the wallets is an administrative wallet, the transaction fee will not be charged.
        if (
            isStaking ||
            isSeedSales ||
            isPrivateSales ||
            isPublicSales ||
            isEcosystemDevelopment ||
            isTeamAddress ||
            isAdvisorsAddress ||
            isTreasuryAddress ||
            isMarketingAddress ||
            isAirdropAddress
        ) {
            super._transfer(from, to, transferAmount);
            return;
        }

        // If the burnOnTransferEnabled flag is set to true, the transaction fee will be charged.
        if (
            burnOnTransferEnabled &&
            balanceOf(msg.sender) < (transferAmount + burnAmount)
        ) {
            transferAmount = amount - burnAmount;
        }

        // Check if the burnOnTransferEnabled flag is set to true and the transaction fee is greater than zero.
        if (burnOnTransferEnabled && burnAmount > 0) {
            super._burn(from, burnAmount);
        }

        // Transfer the remaining amount after the transaction fee has been deducted.
        super._transfer(from, to, transferAmount);
    }

    // Administrative function to set the annual interest rate.
    function setAnnualInterestRate(uint256 _interestRate) external onlyOwner {
    
        require(
            _interestRate >= 10000,
            "Interest rate cannot be less than 10%"
        );
        annualInterestRate = _interestRate;
    }

    // roundDow is used to round down the amount to the nearest integer
    function roundDown(uint256 value, uint256 decimals) private pure returns (uint256) {
        uint256 factor = 10 ** decimals;
        return (value / factor) * factor;
    }

    //  Get the accrued interest for a user.
    function getAccruedInterest(address _user, uint256 stakeIndex) private view returns (uint256) {
        
        require(stakeIndex < stakes[_user].length, "Invalid stake index");

        // Check if the user has a stake.
        Stake storage userStake = stakes[_user][stakeIndex];

        // If the user does not have a stake, the function will return zero.
        if (userStake.amount == 0) {
            return 0;
        }

        uint256 stakedAmount = userStake.amount;
        uint256 interestRate = userStake.interestRate;
        uint256 lastInterestCalculationTime = userStake.lastInterestCalculationTime;
        uint256 currentTime = block.timestamp;

        uint256 stakingDuration = currentTime - lastInterestCalculationTime;
        uint256 additionalInterest = (
            stakedAmount * interestRate * stakingDuration) / 
            (365 days * INTEREST_RATE_SCALE);

        uint256 totalAccruedInterest = userStake.accruedInterest + additionalInterest;

        uint256 round = roundDown(totalAccruedInterest, 13);

        // Return the accrued interest.
        return round;
    }

    // public function to set the minimum staking duration
    function setMinStakingDuration(uint256 _days) external onlyOwner {
        require(_days >= 30, "Rhino: Minimum staking duration cannot be less than 30 days");
        minStakingDuration = _days * 1 days;
    }

    // public function to set the minimum stake value
    function setMinStakeValue(uint256 _value) external onlyOwner {
        require(_value >= 100, "Rhino: Minimum stake value cannot be less than 100 EFY");
        minStakeValue = _value;
    }

    // Administrative function to toggle unStakeBlockLimit
    function toggleUnStakeBlockLimit(bool _enabled) external onlyOwner {
        unStakeBlockLimit = _enabled;
    }

    // Public function to stake tokens.
    function stake(uint256 _amount) external {

        // Check if the amount is greater or equal than minStakeValue.
        require(
            _amount >= minStakeValue, 
            "Rhino: Stake amount is less than the minimum required"
        );

        // Check if the user has enough tokens to stake.
        require(
            _amount <= balanceOf(msg.sender),
            "Rhino: Insufficient balance"
        );

        // Transfer the tokens to the staking administrative address.
        require(transfer(TREASURY_ADDRESS, _amount), "Rhino: Token transfer failed");

        Stake memory newStake = Stake({
            amount: _amount,
            interestRate: annualInterestRate,
            startTime: block.timestamp,
            endTime: 0,
            lastInterestCalculationTime: block.timestamp,
            accruedInterest: 0
        });

        stakes[msg.sender].push(newStake);

        emit NewStake(msg.sender);
    }

    // Public function to unstake tokens.
    function unstake(uint256 stakeIndex) external {

        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");

        Stake storage userStake = stakes[msg.sender][stakeIndex];

        // Check if account is frozen
        require(!_freezeList[msg.sender], "Rhino: account is frozen");

        // Check if the user has a stake.
        require(userStake.amount > 0, "No stake found");

        // Check if the staking duration is greater than or equal to 30 days.
        uint256 stakingDuration = block.timestamp - userStake.startTime;

        if (unStakeBlockLimit) {
            require(
                stakingDuration >= minStakingDuration,
                "Minimum staking duration is not met"
            );
        }

        // Calculate the accrued interest and the total amount.
        uint256 accruedInterest = getAccruedInterest(msg.sender, stakeIndex);
        uint256 totalAmount = userStake.amount + accruedInterest;

        // Delete the stake.
        delete stakes[msg.sender][stakeIndex];

        // Transfer the tokens to the user from Staking administrative address.
        _transfer(STAKING_ADDRESS, msg.sender, totalAmount);
    }

    // Public function to get the stakes for a user.
    function getStakes(address _user) external view virtual returns (
        uint256[] memory, 
        uint256[] memory, 
        uint256[] memory, 
        uint256[] memory,
        uint256[] memory) {

        require(_user == msg.sender || msg.sender == owner(), "Rhino: Unauthorized");

        uint256 stakeCount = stakes[_user].length;
        uint256[] memory indexes = new uint256[](stakeCount);
        uint256[] memory startTimes = new uint256[](stakeCount);
        uint256[] memory amounts = new uint256[](stakeCount);
        uint256[] memory interestRates = new uint256[](stakeCount);
        uint256[] memory accruedInterest = new uint256[](stakeCount);

        for (uint256 i = 0; i < stakeCount; i++) {

            indexes[i] = i;
            startTimes[i] = stakes[_user][i].startTime;
            amounts[i] = stakes[_user][i].amount;
            interestRates[i] = stakes[_user][i].interestRate;
            accruedInterest[i] = getAccruedInterest(_user, i);
        }

        return (indexes, startTimes, amounts, interestRates, accruedInterest);
    }

    // Administrative function mint tokens new tokens based on the allocation percentage.
    function vesting(address account, uint256 amount) public onlyOwner {
        require(
            _allocationPercentage[account] > 0,
            "Rhino: Account not eligible for vesting"
        );

        // Check the allocation limit and the total supply.
        uint256 allocationLimit = (cap() * _allocationPercentage[account]) /
            100;

        // Check if the allocation for the account limit is exceeded.
        require(
            _allocationMinted[account] + amount <= allocationLimit,
            "Rhino: Allocation exceeded"
        );

        // Check if the amount not exceed the total supply.
        require(totalSupply() + amount <= cap(), "Rhino: Max supply exceeded");

        // Mint the tokens to the account.
        _allocationMinted[account] += amount;
        _mint(account, amount);
    }

    // Administrative function to freeze an account.
    function freezeAddress(address account) external onlyOwner {
        // Check if the account is already frozen.
        require(!_freezeList[account], "Rhino: account is already frozen");

        // Freeze the account.
        _freezeList[account] = true;
        emit FrozenAccount(account, true);
    }

    // Administrative function to unfreeze an account.
    function unFreezeAddress(address account) external onlyOwner {
        // Check if the account is frozen.
        require(_freezeList[account], "Rhino: account is not frozen");

        // Unfreeze the account.
        delete _freezeList[account];
        emit FrozenAccount(account, false);
    }

    // Check if the account is frozen.
    function freezeAddressList(address account) external view virtual returns (bool) {
        return _freezeList[account];
    }

    // Administrative function to set the burn rate.
    function setBurnRate(uint256 newBurnRate) external onlyOwner {
        // Check if the burn rate is between 0% and 3%.
        require(newBurnRate <= 3000, "Burn rate must be between 0% and 3%");
        burnRate = newBurnRate;
    }

    // Administrative function to set the burn rate and change the burn status
    // on transfers.
    function toggleBurn(bool _enabled) external onlyOwner returns (bool) {
        burnOnTransferEnabled = _enabled;
        return burnOnTransferEnabled;
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        // Check if the account is in _allocationMinted
        if (_allocationMinted[account] > 0) {
            // Subtract the burned amount from _allocationMinted
            //uint256 newAllocationMinted = amount;
            //_allocationMinted[account] -= newAllocationMinted;
        }
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

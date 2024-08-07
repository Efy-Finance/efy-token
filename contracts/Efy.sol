// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EFYBase.sol";
import "./EFYStaking.sol";
import "./EFYMint.sol";
import "./EFYWhiteList.sol";

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
    EFYStaking public stakingContract;
    EFYMint public mintContract;
    EFYWhitelist public whiteListContract;
    EFYBase public configContract;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event AllocationMinted(address indexed account, uint256 amount);
    event AddressFrozen(address indexed account);
    event AddressUnfrozen(address indexed account);
    event AnnualInterestRateUpdated(uint256 newRate);
    event BurnedFee(uint256 amountSended, uint256 burnedAmount);

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
        configContract = new EFYBase(addresses, owner());
        stakingContract = new EFYStaking(address(this), address(configContract));
        mintContract = new EFYMint(address(this), address(configContract), owner());
        whiteListContract = new EFYWhitelist();

        _mintInitialSupply(addresses);
    }

    // Modifier to restrict access to mint, only the mint contract can call 
    modifier onlyMintContract() {
        require(msg.sender == address(mintContract), "Only mint contract can call this function");
        _;
    }
    
    // Mint initial supply function 
    function _mintInitialSupply(address[10] memory addresses) private {
        uint256 _cap = cap();

        _mint(addresses[2], (_cap * 12) / 100); // PUBLIC_SALES
        _mint(addresses[3], (_cap * 11) / 100); // ECOSYSTEM_DEVELOPMENT
        _mint(addresses[6], (_cap * 10) / 100); // MARKETING_ADDRESS
        _mint(addresses[7], (_cap * 30) / 100); // TREASURY_ADDRESS
        _mint(addresses[8], (_cap * 2) / 100);  // AIRDROP_ADDRESS
        _mint(addresses[9], (_cap * 10) / 100); // STAKING_ADDRESS
    }

    // Administrative function to set the config contract
    function setConfigContract(address _configContract) external onlyOwner {
        configContract = EFYBase(_configContract);
    }

    // Administrative function to set the staking contract
    function setStakingContract(address _configContract) external onlyOwner {
        stakingContract = EFYStaking(_configContract);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {

        // Check if the sender and recipient are frozen
        require(!whiteListContract.isFrozen(from), "EFYFinance: Sender account is frozen");
        require(!whiteListContract.isFrozen(to), "EFYFinance: Recipient account is frozen");

        super._beforeTokenTransfer(from, to, amount);
    }

    // Transfer function
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        // Check if the transfer is exempt from fees
        if (configContract.isExemptFromFees(from) || configContract.isExemptFromFees(to)) {
            super._transfer(from, to, amount);
            return;
        }

        bool isBurnEnabled = configContract.isBurnEnabled();
        uint256 transferAmount = amount;

        // Check if burn is enabled
        if(isBurnEnabled) {

            uint256 burnRate = configContract.getBurnRate();
            uint256 burnAmount = (amount * burnRate / configContract.BURN_RATE_SCALE());
            uint256 userBalance = balanceOf(from);

            if (userBalance > amount){
                // User's balance is not enough to cover the full burn amount
                // Adjust the burn amount based on the user's balance
                burnAmount = userBalance - amount;
                transferAmount = amount;
            }

            else {
                // User's balance is not enough to cover the full burn amount
                // Adjust the burn amount based on the user's balance
                transferAmount = userBalance;
                burnAmount = (transferAmount * burnRate) / configContract.BURN_RATE_SCALE();
                transferAmount -= burnAmount;
            }

            // Burn the amount
            super._burn(from, burnAmount);

            // Emit the burn event
            emit BurnedFee(transferAmount, burnAmount);
        }

        // Check if the transfer amount is greater than 0
        require(transferAmount > 0, "Transfer amount too small");

        super._transfer(from, to, transferAmount);
    }

     // Staking function
    function stake(uint256 amount) external whenNotPaused {
        // Check if the user has enough balance
        require(balanceOf(msg.sender) >= amount, "EFYFinance: Insufficient balance");

        // Transfer the amount to the staking wallet
        _transfer(msg.sender, configContract.getTreasuruyWallet(), amount);

        // Call the staking contract to stake the amount
        stakingContract.stake(msg.sender, amount);

        // Emit the stake event
        emit Staked(msg.sender, amount);
    }

    // Unstake function
    function unstake(uint256 stakeIndex) external whenNotPaused {

        // Call the staking contract to unstake the stake
        (uint256 amount, uint256 accruedInterest) = stakingContract.unstake(msg.sender, stakeIndex);

        // Check if the amount is greater than 0
        require(amount > 0, "No stake found");
        
        // Transfer initial stake amount from the treasury wallet to the user
        address treasuryWallet = configContract.getTreasuruyWallet();
        _transfer(treasuryWallet, msg.sender, amount);

        // Transfer accrued interest from the staking wallet to the user
        address stakingWallet = configContract.getStakingWallet();
        _transfer(stakingWallet, msg.sender, accruedInterest);

        // Emit the unstake event
        emit Unstaked(msg.sender, amount);
    }

    // Get stakes function
     function getStakes(address user, uint256 startIndex, uint256 limit) external view returns (
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        return stakingContract.getStakes(user, startIndex, limit);
    }

    // Whitelist functions

    function freezeAddress(address account) external onlyOwner {
        // Call the whitelist contract to freeze the address
        whiteListContract.freezeAddress(account);

        // Emit the address frozen event
        emit AddressFrozen(account);
    }

    function unFreezeAddress(address account) external onlyOwner {
        // Call the whitelist contract to unfreeze the address
        whiteListContract.unFreezeAddress(account);

        // Emit the address unfrozen event
        emit AddressUnfrozen(account);
    }


    // misc functions

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
    }

    function mint(address to, uint256 amount) public onlyMintContract returns (bool) {
        _mint(to, amount);
        emit AllocationMinted(to, amount);
        return true;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EFYBase.sol";

interface IEFYFinance {
    function mint(address to, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function cap() external view returns (uint256);
}

/**
 * @title Rhinostec / Contract to EfyFinance
 * @custom:security-contact dev@rhinostec.com
 */

contract EFYMint is Ownable {
    IEFYFinance public efyToken;
    EFYBase public configContract;

    mapping(address => uint256) internal _allocationMinted;

    constructor(address _efyToken, address _configContract, address _owner) {

        efyToken = IEFYFinance(_efyToken);
        configContract = EFYBase(_configContract);
        
        _transferOwnership(_owner);
    }


    function mintAllocation(address account, uint256 amount) public onlyOwner {

        // Check if the account is eligible for vesting
        require(
            configContract.getAllocationPercentage(account) > 0,
            "EFYMint: Account not eligible for vesting"
        );

        // Calculate the totalallocation limit
        uint256 allocationLimit = (efyToken.totalSupply() * configContract.getAllocationPercentage(account)) / 100;

        // Check if the allocation has not exceeded the limit
        require(
            _allocationMinted[account] + amount <= allocationLimit,
            "EFYMint: Allocation exceeded"
        );

        // Check if the total supply of EFY tokens has not exceeded the cap
        require(efyToken.totalSupply() + amount <= efyToken.cap(), "EFYMint: Max supply exceeded");

        // Update the allocation minted amount
        _allocationMinted[account] += amount;
        
        // Mint the allocation amount
        require(efyToken.mint(account, amount), "EFYMint: Minting failed");
    }
}

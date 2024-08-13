// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Rhinostec / Contract to EfyFinance
 * @custom:security-contact dev@rhinostec.com
 */

contract EFYWhitelist is Ownable {

    mapping(address => bool) internal _freezeList;

    event FrozenAccount(address indexed account);
    event UnFrozenAccount(address indexed account);

    address public immutable efyToken;

    modifier onlyEFYFinance() {
        require(msg.sender == address(efyToken), "EFYWhitelist: Only EFYFinance contract can call this function");
        _;
    }

    constructor(address efy, address safeOwner) {
        efyToken = efy;
        _transferOwnership(safeOwner);
    }

    // Administrative function to freeze an address
    function freezeAddress(address account) external onlyEFYFinance {
        require(!_freezeList[account], "EFY Blacklist: account is already frozen");
        _freezeList[account] = true;
        emit FrozenAccount(account);
    }

    // Administrative function to unfreeze an address
    function unFreezeAddress(address account) external onlyEFYFinance {
        require(_freezeList[account], "EFY Blacklist: account is not frozen");
        delete _freezeList[account];
        emit UnFrozenAccount(account);
    }

    // return the freeze status of an address
    function isFrozen(address account) external view returns (bool) {
        return _freezeList[account];
    }
}

![EFYFInanceLogo](https://www.efyfinance.com/assets/img/logos/efy-logo.svg)
## EFY Token - Smart Contract for EfyFinance

EFY Token is an ERC20 token contract built using Solidity and the OpenZeppelin library. It incorporates various token standards and features, including ERC20 token transfers, burning, capping, pausing, and permitting.

Features

**ERC20 Token:** EFY Token follows the ERC20 token standard, allowing for basic token transfers and balance management.

**Burnable:** Tokens can be burned (destroyed) by token holders, reducing the total supply.

**Capped:** The total supply of tokens is capped at a specified maximum value.

**Pausable:** Token transfers can be paused and unpaused by the contract owner.

**Permit:** Allows token holders to grant approvals to other addresses using off-chain signatures.

**Access Control:** The contract includes access control mechanisms, such as the Ownable contract, to restrict certain functions to the contract owner.

**Staking:** Users can stake their tokens and earn interest based on the staking duration and the specified annual interest rate.

**Vesting:** The contract supports token vesting, allowing for the gradual release of tokens to specific addresses over time.

**Freezing:** The contract owner can freeze and unfreeze specific addresses, preventing them from transferring tokens.

**Burn on Transfer**: A configurable percentage of tokens can be burned during each transfer.

To use the EFY Token contract in your project, follow these steps:

1.  Clone the repository:
    ```
        git clone https://github.com/Efy-Finance/efytoken
    ```
2.  Install the dependencies
    ```
        cd efytoken npm install
    ```

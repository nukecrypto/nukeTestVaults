# nukeTestVaults Review
## By: Carter Carlson

## High
### 1. Poor practice- sensitive data
Following the README, if a developer creates a `.secret` file with their mnemonic and commits all files, their mnemonic will be published on a public repository.

**Suggestion:** Add the sensitive file to ignore to `.gitignore`.  Also, follow [common practice](https://www.twilio.com/blog/working-with-environment-variables-in-node-js-html) of providing a template `.env.example` as a guideline for developers to fill out for their own `.env` file.  

### 2. No slippage tolerance
There is no minimum slippage tolerance when calling `IUniswapRouterV2(SUSHISWAP_ROUTER).swapExactTokensForTokens()`, which would be exploited by MEV.

**Suggestion:** Apply a maximum slippage allowance.


## Low
### Deprecated keywords
The keyword variable `now` is deprecated and should be `block.timestamp`.

## Informational

### Incorrect interface conventions
Follow best practice of prepending all interface files and interfaces with `I`.

### Outdated versioning
Following solidity v0.8 there is no need to implement safemath.  There is no need to use an outdated solidity version with an extra library.

Truffle is battle-tested but not as commonly used as it used to be.

**Suggestion:** implement solidity v0.8 and a more common testing framework like hardhat or foundry.

### Poor documentation
Natspec documentation should be used for all public/external variables and functions.

### Incorrect constructor
Constructor visibility is ignored.  No need to declare public.

### Unused variables
Several contract variables are defined and never used.

**Suggestion:** only define variables that are used.

### Incorrect visibility function ordering
Declare functions in the right order - public, external, internal, private, views.

### Broken deployment script
```
carter@book:~/Documents/consult/gigs/nukeTestVaults$ npx truffle migrate --reset --compile-all --network avax

Compiling your contracts...
===========================
> Compiling ./contracts/EpicStrategy_Avax_Curve_Aave.sol
> Compiling ./contracts/EpicVault.sol
> Compiling ./interfaces/curve/ICurve.sol
> Compiling ./interfaces/nuke/EpicStrategy.sol
> Compiling ./interfaces/nuke/IEpicVault.sol
> Compiling ./interfaces/uniswap/Uni.sol
> Compiling ./openzeppelin-contracts/contracts/access/Ownable.sol
> Compiling ./openzeppelin-contracts/contracts/security/Pausable.sol
> Compiling ./openzeppelin-contracts/contracts/token/ERC20/ERC20.sol
> Compiling ./openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
> Compiling ./openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol
> Compiling ./openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
> Compiling ./openzeppelin-contracts/contracts/utils/Address.sol
> Compiling ./openzeppelin-contracts/contracts/utils/Context.sol
> Compiling ./openzeppelin-contracts/contracts/utils/math/SafeMath.sol
> Compilation warnings encountered:

    Warning: This declaration has the same name as another declaration.
  --> project:/interfaces/curve/ICurve.sol:14:39:
   |
14 |     function withdraw(uint256 _value, bool claim_rewards) external;
   |                                       ^^^^^^^^^^^^^^^^^^
Note: The other declaration is here:
  --> project:/interfaces/curve/ICurve.sol:16:5:
   |
16 |     function claim_rewards() external;
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Note: The other declaration is here:
  --> project:/interfaces/curve/ICurve.sol:18:5:
   |
18 |     function claim_rewards(address addr) external;
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

,Warning: Visibility for constructor is ignored. If you want the contract to be non-deployable, making it "abstract" is sufficient.
  --> project:/contracts/EpicStrategy_Avax_Curve_Aave.sol:56:5:
   |
56 |     constructor(address _vault) public {
   |     ^ (Relevant source part starts here and spans across multiple lines).


> Artifacts written to /home/carter/Documents/consult/gigs/nukeTestVaults/build/contracts
> Compiled successfully using:
   - solc: 0.8.0+commit.c7dfd78e.Emscripten.clang


Starting migrations...
======================
> Network name:    'avax'
> Network id:      43113
> Block gas limit: 8000000 (0x7a1200)


1_initial_migration.js
======================

   Deploying 'EpicVault'
   ---------------------
   > transaction hash:    0x0eb38235e93bc419e335a0193f357ee8c30b7f9c48e7768b2c45c9feadbb5136
   > Blocks: 2            Seconds: 4
   > contract address:    0x71e40cb1Ed5b63Bd3CAE734975230eb18D7aD6aA
   > block number:        9001184
   > block timestamp:     1651012790
   > account:             0xA1f5Cf303608BA59E0ad9df31C46d0826ef27720
   > balance:             8.98991991
   > gas used:            3311738 (0x32887a)
   > gas price:           305 gwei
   > value sent:          0 ETH
   > total cost:          1.01008009 ETH

   Pausing for 1 confirmations...

   -------------------------------
   > confirmation number: 1 (block: 9001187)

   Deploying 'EpicStrategy_Avax_Curve_Aave'
   ----------------------------------------
   > transaction hash:    0x3827d7d6c1ecbbe7ab5cd94162e516a9bf700d0097456337e81f0185165fa968
   > Blocks: 0            Seconds: 0
   > contract address:    0xD42811fF2C08A90050BA0762C30f09Bd18907FE9
   > block number:        9001192
   > block timestamp:     1651012806
   > account:             0xA1f5Cf303608BA59E0ad9df31C46d0826ef27720
   > balance:             7.87757027
   > gas used:            3647048 (0x37a648)
   > gas price:           305 gwei
   > value sent:          0 ETH
   > total cost:          1.11234964 ETH

   Pausing for 1 confirmations...

   -------------------------------

/home/carter/Documents/consult/gigs/nukeTestVaults/node_modules/eth-block-tracker/src/polling.js:51
        const newErr = new Error(`PollingBlockTracker - encountered an error while attempting to update latest block:\n${err.stack}`)
                       ^
Error: PollingBlockTracker - encountered an error while attempting to update latest block:
undefined
    at PollingBlockTracker._performSync (/home/carter/Documents/consult/gigs/nukeTestVaults/node_modules/eth-block-tracker/src/polling.js:51:24)
    at processTicksAndRejections (node:internal/process/task_queues:96:5)
```
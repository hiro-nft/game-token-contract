# game-token-contract

# Game-Token
GameToken is a smart contract that implements various features such as ERC20 token functionality, pausable behavior, access control, fee management, and permit functionality. It also includes upgradeable features and interfaces with an underlying ERC20 token.

# Notable Features:
1. This contract includes roles for pausing, upgrading, and ignoring fees.
2. It manages deposit and withdrawal fees, and tracks the fee balance.
3. It has specific weight values for different tokens (hiroWeight and gameWeight).
4. It uses OpenZeppelin libraries for ERC20, pausable, access control, permit, and upgradeable functionality.

# Install and run
```shell
npx hardhat init
npx hardhat node
npm install --save-dev @openzeppelin/hardhat-upgrades @nomicfoundation/hardhat-ethers ethers
npx hardhat compile
npx hardhat test
npx hardhat run --network localhost scripts/deploy.js // deploy
```

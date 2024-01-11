// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable@4.8.3/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.3/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.3/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.3/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.3/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.3/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.8.3/token/ERC20/utils/SafeERC20Upgradeable.sol"; // @ must be deleted in redhat.

contract Middle2Token is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant IGNORE_FEE_ROLE = keccak256("IGNORE_FEE_ROLE");

    uint256 private constant FEE_MAX_PERCENT = 1000000000; // 10**9

    uint256 public depositFeePercent;
    uint256 public withdrawFeePercent;
    uint256 public feeBalance;

    uint256 public hiroWeight;
    uint256 public gameWeight;

    IERC20Upgradeable public underlying;

    event DepositFor(address indexed owner,uint256 amount,uint256 amountAfterFee,uint256 fee);
    event WithdrawTo(address indexed owner,uint256 amount,uint256 amountAfterFee,uint256 fee);
    event SetDepositFee(uint256 oldFeePercent, uint256 newFeePercent);
    event SetWithdrawFee(uint256 oldFeePercent, uint256 newFeePercent);
    event WithdrawFee(address indexed account, uint256 amount);



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        IERC20Upgradeable underlyingToken,
        uint256 initdepositFeePercent,
        uint256 initwithdrawFeePercent
    ) initializer public {
        require(address(underlyingToken) != address(0),"Underlying token must not be zero address");
        require(initdepositFeePercent <= FEE_MAX_PERCENT,"depositFee must not be greater than FEE_MAX_PERCENT");
        require(initwithdrawFeePercent <= FEE_MAX_PERCENT,"withdrawFee must not be greater than FEE_MAX_PERCENT");

        __ERC20_init(tokenName, tokenSymbol);
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(tokenName);
        __UUPSUpgradeable_init();

        underlying = underlyingToken;

        feeBalance = 0;
        depositFeePercent = initdepositFeePercent;
        withdrawFeePercent = initwithdrawFeePercent;
        hiroWeight = 1000;
        gameWeight = 1000;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // delete
    // function getImplementation() external view returns (address) {
    //     return _getImplementation();
    // }

    /**
     * Calculate the feeBalance you will receive upon Deposit.
     * When calculating feeBalance, the remainder is cut off.
     */
    function _calcuDepositFeePercent(address account, uint256 amount)
        internal view returns (uint256 fee, uint256 amountAfterFee)
    {
        if (hasRole(IGNORE_FEE_ROLE, account)) {
            fee = 0;
            amountAfterFee = amount;
        } else {
            fee = amount * depositFeePercent / FEE_MAX_PERCENT;
            amountAfterFee = amount - fee;
        }
    }

    /**
     * Calculate the feeBalance you will receive upon withdrawal.
     * When calculating feeBalance, the remainder is cut off.
     */
    function _calcuWithdrawFeePercent(address account, uint256 amount)
        internal view returns (uint256 fee, uint256 amountAfterFee)
    {
        if (hasRole(IGNORE_FEE_ROLE, account)) {
            fee = 0;
            amountAfterFee = amount;
        } else {
            fee = amount * withdrawFeePercent / FEE_MAX_PERCENT;
            amountAfterFee = amount - fee;
        }
    }

    /**
     * Set the DEPOSIT fee.
     */
    function setDepositFee(uint256 newPercent)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newPercent < FEE_MAX_PERCENT, "Max fee reach");
        uint256 oldFeePercent = depositFeePercent;
        depositFeePercent = newPercent;
        emit SetDepositFee(oldFeePercent, depositFeePercent);
    }

    /**
     * Set the WITHDRAW fee.
     */
    function setWithdrawFee(uint256 newPercent)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newPercent < FEE_MAX_PERCENT, "Max fee reach");
        uint256 oldFeePercent = withdrawFeePercent;
        withdrawFeePercent = newPercent;
        emit SetWithdrawFee(oldFeePercent, withdrawFeePercent);
    }

    /**
     * Make a deposit. As Hero Tokens arrive, game tokens are sent at a set rate.
     */
    function depositFor(address owner, uint256 amount)
        public
        returns (bool)
    {
        (uint256 fee, uint256 amountAfterFee) = _calcuDepositFeePercent(_msgSender(),amount);

        // require(amount <= underlying.balanceOf(_msgSender()), "not enough balance");
        SafeERC20Upgradeable.safeTransferFrom(underlying,_msgSender(),address(this),amount);
        feeBalance = feeBalance + fee;

        _mint(owner, amountAfterFee*gameWeight/hiroWeight);

        emit DepositFor(owner, amount, amountAfterFee, fee);
        return true;
    }

    /**
     * Burn the token you have and withdraw it with Hiro Token.
     */
    function withdrawTo(address owner, uint256 amount)
        public
        returns (bool)
    {
        uint256 tmpAmount = amount*hiroWeight/gameWeight;
        require(tmpAmount + feeBalance <= underlying.balanceOf(address(this)), "not enough balance");
        (uint256 fee, uint256 amountAfterFee) = _calcuWithdrawFeePercent(_msgSender(), tmpAmount);
        _burn(_msgSender(), amount);
        feeBalance = feeBalance + fee;
        SafeERC20Upgradeable.safeTransfer(underlying, owner, amountAfterFee);

        emit WithdrawTo(owner, amount, amountAfterFee, fee);
        return true;
    }

    /**
     * Check the amount that can be withdrawn.
     * The amount received as a fee is subtracted from the calculation.
     */
    function isWithdraw()
        public whenNotPaused view returns (uint256)
    {
        uint256 underlyingBalance = underlying.balanceOf(address(this));
        if (underlyingBalance > feeBalance) {
            return underlyingBalance - feeBalance;
        }
        return 0;
    }

    function setWeight(uint256 hiro, uint256 game)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        hiroWeight = hiro;
        gameWeight = game;
    }
    /**
     * Withdraw the tokens received as a fee.
     */
    function withdrawFee(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), "address is required");
        require(to != address(this), "address must not be self address");
        require(feeBalance > 0, "no more fee to withdraw");
        uint256 balanceToWithdraw = feeBalance;
        feeBalance = 0;
        SafeERC20Upgradeable.safeTransfer(underlying, to, balanceToWithdraw);

        emit WithdrawFee(to, balanceToWithdraw);
    }


    /**
     * @dev Allow a user to deposit underlying tokens and mint the corresponding number of wrapped tokens.
     * Execute depositFor after approval.
     */
    function permitAndDepositFor(uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
        external whenNotPaused {
        IERC20PermitUpgradeable(address(underlying)).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        depositFor(msg.sender, _amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}

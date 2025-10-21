// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 * @author [Tu Nombre] - Ethereum Developer Pack
 * @notice This contract allows users to deposit and withdraw native tokens (ETH) with a personal vault system
 * @dev Implements security patterns: Check-Effects-Interactions, custom errors, and modifiers
 * @custom:security This is an educational contract for the Ethereum Developer Pack course
 */
contract KipuBank {
    /*///////////////////////////////////////////////////////////////
                            TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/

    // No type declarations needed for this contract

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Immutable withdrawal threshold per transaction
    /// @dev Set during deployment and cannot be changed
    uint256 public immutable i_withdrawalThreshold;

    /// @notice Global deposit cap for the entire bank
    /// @dev Total deposits across all users cannot exceed this amount
    uint256 public immutable i_bankCap;

    /// @notice Owner of the contract
    /// @dev Has administrative privileges
    address private immutable i_owner;

    /// @notice Mapping to store each user's vault balance
    /// @dev Maps user address to their deposited amount
    mapping(address user => uint256 balance) private s_balances;

    /// @notice Total number of deposits made to the contract
    uint256 private s_depositCount;

    /// @notice Total number of withdrawals made from the contract
    uint256 private s_withdrawalCount;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user successfully deposits ETH
    /// @param user Address of the user making the deposit
    /// @param amount Amount of ETH deposited in wei
    event KipuBank__DepositSuccessful(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully withdraws ETH
    /// @param user Address of the user making the withdrawal
    /// @param amount Amount of ETH withdrawn in wei
    event KipuBank__WithdrawalSuccessful(address indexed user, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error thrown when deposit would exceed the bank cap
    /// @param currentTotal Current total deposits in the bank
    /// @param attemptedDeposit Amount user is trying to deposit
    /// @param bankCap Maximum allowed total deposits
    error KipuBank__BankCapExceeded(uint256 currentTotal, uint256 attemptedDeposit, uint256 bankCap);

    /// @notice Error thrown when user has insufficient balance for withdrawal
    /// @param user Address of the user
    /// @param available Available balance
    /// @param requested Requested withdrawal amount
    error KipuBank__InsufficientBalance(address user, uint256 available, uint256 requested);

    /// @notice Error thrown when withdrawal amount exceeds the threshold
    /// @param requested Requested withdrawal amount
    /// @param threshold Maximum allowed per transaction
    error KipuBank__WithdrawalThresholdExceeded(uint256 requested, uint256 threshold);

    /// @notice Error thrown when ETH transfer fails
    /// @param recipient Address that should have received ETH
    error KipuBank__TransferFailed(address recipient);

    /// @notice Error thrown when caller is not the owner
    /// @param caller Address of the caller
    /// @param owner Address of the actual owner
    error KipuBank__NotOwner(address caller, address owner);

    /// @notice Error thrown when deposit amount is zero
    error KipuBank__DepositAmountZero();

    /*///////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Restricts function access to contract owner only
    /// @dev Reverts with KipuBank__NotOwner if caller is not the owner
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert KipuBank__NotOwner(msg.sender, i_owner);
        }
        _;
    }

    /// @notice Validates that withdrawal amount doesn't exceed threshold
    /// @param _amount Amount to validate
    /// @dev Reverts with KipuBank__WithdrawalThresholdExceeded if amount exceeds threshold
    modifier withinThreshold(uint256 _amount) {
        if (_amount > i_withdrawalThreshold) {
            revert KipuBank__WithdrawalThresholdExceeded(_amount, i_withdrawalThreshold);
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the KipuBank contract
     * @param _withdrawalThreshold Maximum amount that can be withdrawn per transaction
     * @param _bankCap Maximum total deposits allowed in the bank
     * @dev Sets immutable values and assigns contract deployer as owner
     */
    constructor(uint256 _withdrawalThreshold, uint256 _bankCap) {
        i_withdrawalThreshold = _withdrawalThreshold;
        i_bankCap = _bankCap;
        i_owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL PAYABLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to deposit ETH into their personal vault
     * @dev Implements Check-Effects-Interactions pattern for security
     * @dev Uses single read and single write to state variable for gas optimization
     */
    function deposit() external payable {
        // CHECKS
        if (msg.value == 0) {
            revert KipuBank__DepositAmountZero();
        }

        uint256 currentBalance = s_balances[msg.sender]; // Single read from storage
        uint256 newTotalDeposits = address(this).balance; // Total including current deposit

        if (newTotalDeposits > i_bankCap) {
            revert KipuBank__BankCapExceeded(
                address(this).balance - msg.value,
                msg.value,
                i_bankCap
            );
        }

        // EFFECTS
        uint256 newBalance;
        unchecked {
            // Safe because we know msg.value > 0 and overflow is virtually impossible
            newBalance = currentBalance + msg.value;
            s_depositCount++;
        }
        
        s_balances[msg.sender] = newBalance; // Single write to storage

        emit KipuBank__DepositSuccessful(msg.sender, msg.value);

        // INTERACTIONS - None in this function
    }

    /**
     * @notice Allows users to withdraw ETH from their vault
     * @param _amount Amount of ETH to withdraw in wei
     * @dev Implements Check-Effects-Interactions pattern
     * @dev Only allows withdrawal up to the threshold defined at deployment
     * @dev Uses single read and single write to state variable
     */
    function withdraw(uint256 _amount) external withinThreshold(_amount) {
        // CHECKS
        uint256 currentBalance = s_balances[msg.sender]; // Single read from storage

        if (_amount > currentBalance) {
            revert KipuBank__InsufficientBalance(msg.sender, currentBalance, _amount);
        }

        // EFFECTS
        uint256 newBalance;
        unchecked {
            // Safe because we already checked _amount <= currentBalance
            newBalance = currentBalance - _amount;
            s_withdrawalCount++;
        }

        s_balances[msg.sender] = newBalance; // Single write to storage

        emit KipuBank__WithdrawalSuccessful(msg.sender, _amount);

        // INTERACTIONS
        _transferETH(msg.sender, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to safely transfer ETH
     * @param _to Recipient address
     * @param _amount Amount to transfer in wei
     * @dev Uses call() for secure ETH transfers
     * @dev Reverts if transfer fails
     */
    function _transferETH(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert KipuBank__TransferFailed(_to);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the vault balance of a specific user
     * @param _user Address of the user to query
     * @return balance_ The user's current balance in wei
     */
    function getBalance(address _user) external view returns (uint256 balance_) {
        balance_ = s_balances[_user];
    }

    /**
     * @notice Returns the total number of deposits made
     * @return count_ Total deposit count
     */
    function getDepositCount() external view returns (uint256 count_) {
        count_ = s_depositCount;
    }

    /**
     * @notice Returns the total number of withdrawals made
     * @return count_ Total withdrawal count
     */
    function getWithdrawalCount() external view returns (uint256 count_) {
        count_ = s_withdrawalCount;
    }

    /**
     * @notice Returns the withdrawal threshold
     * @return threshold_ Maximum amount that can be withdrawn per transaction
     */
    function getWithdrawalThreshold() external view returns (uint256 threshold_) {
        threshold_ = i_withdrawalThreshold;
    }

    /**
     * @notice Returns the bank cap
     * @return cap_ Maximum total deposits allowed
     */
    function getBankCap() external view returns (uint256 cap_) {
        cap_ = i_bankCap;
    }

    /**
     * @notice Returns the contract owner address
     * @return owner_ Address of the contract owner
     */
    function getOwner() external view returns (address owner_) {
        owner_ = i_owner;
    }

    /**
     * @notice Returns the total ETH held in the contract
     * @return total_ Total balance in wei
     */
    function getTotalBalance() external view returns (uint256 total_) {
        total_ = address(this).balance;
    }
}

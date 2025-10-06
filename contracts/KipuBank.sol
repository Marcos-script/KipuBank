// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank - Un banco simple en Solidity para depósitos y retiros.
/// @author Marcos
/// @notice Permite depositar y retirar ETH con límites de seguridad.
/// @dev Ejemplo de buenas prácticas en Solidity.

contract KipuBank {
    // --- VARIABLES DE ESTADO ---
    address public immutable owner; // dueño del contrato
    uint256 public immutable withdrawLimit; // límite fijo por retiro
    uint256 public immutable bankCap; // límite total de depósitos

    uint256 public totalDeposited; // total de ETH depositados
    uint256 public totalDeposits; // número de depósitos
    uint256 public totalWithdrawals; // número de retiros

    mapping(address => uint256) public balances; // saldo de cada usuario

    // --- EVENTOS ---
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // --- ERRORES PERSONALIZADOS ---
    error NotOwner();
    error DepositLimitExceeded();
    error WithdrawLimitExceeded();
    error InsufficientBalance();

    // --- CONSTRUCTOR ---
    constructor(uint256 _withdrawLimit, uint256 _bankCap) {
        owner = msg.sender;
        withdrawLimit = _withdrawLimit;
        bankCap = _bankCap;
    }

    // --- MODIFICADOR ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // --- FUNCIONES PRINCIPALES ---

    /// @notice Deposita ETH en tu cuenta dentro del contrato.
    function deposit() external payable {
        if (totalDeposited + msg.value > bankCap) revert DepositLimitExceeded();

        balances[msg.sender] += msg.value;
        totalDeposited += msg.value;
        totalDeposits++;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Retira una cantidad de ETH, respetando el límite por transacción.
    function withdraw(uint256 _amount) external {
        if (_amount > withdrawLimit) revert WithdrawLimitExceeded();
        if (balances[msg.sender] < _amount) revert InsufficientBalance();

        balances[msg.sender] -= _amount;
        totalDeposited -= _amount;
        totalWithdrawals++;

        payable(msg.sender).transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice Consulta el balance del usuario.
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }

    // --- FUNCIONES PARA RECIBIR ETH DIRECTAMENTE ---
    receive() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits++;
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits++;
        emit Deposit(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title KipuBank - Bóveda para depósitos y retiros con límites y seguridad
/// @author Marcos
/// @notice Permite depositar ETH nativo en saldos personales, retirar hasta un límite por tx y respetar un bankCap global.
/// @dev Implementa errors personalizados, checks-effects-interactions, nonReentrant guard y helpers privados.
contract KipuBank {
    /* ========== ERRORS ========== */
    /// @notice Revert cuando el monto es cero
    error ZeroAmount();

    /// @notice Revert cuando el banco no tiene espacio suficiente
    /// @param available saldo restante (wei)
    /// @param attempted intento de depósito (wei)
    error ExceedsBankCap(uint256 available, uint256 attempted);

    /// @notice Revert cuando el retiro excede el límite por transacción
    /// @param requested monto pedido (wei)
    /// @param limit límite por transacción (wei)
    error ExceedsPerTxLimit(uint256 requested, uint256 limit);

    /// @notice Revert cuando el usuario no tiene saldo suficiente
    /// @param who dirección del usuario
    /// @param available saldo disponible (wei)
    /// @param requested monto solicitado (wei)
    error InsufficientBalance(address who, uint256 available, uint256 requested);

    /// @notice Revert cuando la transferencia externa falla
    /// @param to destino
    /// @param amount monto en wei
    error TransferFailed(address to, uint256 amount);

    /// @notice Revert cuando se detecta reentrancy
    error Reentrancy();

    /* ========== EVENTS ========== */
    event Deposit(address indexed who, uint256 amount, uint256 newBalance, uint256 timestamp);
    event Withdraw(address indexed who, uint256 amount, uint256 newBalance, uint256 timestamp);

    /* ========== STATE ========== */

    /// @notice Owner del contrato (deploy)
    address public immutable owner;

    /// @notice Límite global de fondos permitido en el contrato (wei)
    uint256 public immutable bankCap;

    /// @notice Límite máximo por retiro (wei)
    uint256 public immutable perTxLimit;

    /// @notice Saldo por usuario (wei)
    mapping(address => uint256) private balances;

    /// @notice Contador de depósitos por usuario
    mapping(address => uint256) public depositsCount;

    /// @notice Contador de retiros por usuario
    mapping(address => uint256) public withdrawalsCount;

    /// @notice Contadores globales
    uint256 public totalDeposited; // suma de saldos actuales (wei)
    uint256 public totalDepositsCount;
    uint256 public totalWithdrawalsCount;

    /// @dev Guard anti-reentrancy simple
    bool private _entered;

    /* ========== MODIFIERS ========== */

    modifier nonReentrant() {
        if (_entered) revert Reentrancy();
        _entered = true;
        _;
        _entered = false;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert(); // opción: definir NotOwner() si querés mensaje
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    /// @param _bankCap límite total de depósitos (wei)
    /// @param _perTxLimit límite máximo por retiro (wei)
    constructor(uint256 _bankCap, uint256 _perTxLimit) {
        if (_bankCap == 0 || _perTxLimit == 0) revert ZeroAmount();
        owner = msg.sender;
        bankCap = _bankCap;
        perTxLimit = _perTxLimit;
    }

    /* ========== CORE FUNCTIONS ========== */

    /// @notice Deposita ETH en tu bóveda (payable)
    function deposit() external payable {
        _handleDeposit(msg.sender, msg.value);
    }

    /// @notice Retira hasta `perTxLimit` desde tu saldo
    /// @param _amount monto en wei a retirar
    function withdraw(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (_amount > perTxLimit) revert ExceedsPerTxLimit(_amount, perTxLimit);

        uint256 bal = balances[msg.sender];
        if (_amount > bal) revert InsufficientBalance(msg.sender, bal, _amount);

        // Effects
        balances[msg.sender] = bal - _amount;
        withdrawalsCount[msg.sender] += 1;
        totalWithdrawalsCount += 1;
        totalDeposited -= _amount;

        // Interaction (safe)
        _safeSend(payable(msg.sender), _amount);

        emit Withdraw(msg.sender, _amount, balances[msg.sender], block.timestamp);
    }

    /* ========== PRIVATE HELPERS ========== */

    /// @notice Maneja la lógica de depósito (checks, effects, event)
    /// @dev Función privada para evitar duplicación en receive/fallback y deposit()
    function _handleDeposit(address _from, uint256 _amount) private {
        if (_amount == 0) revert ZeroAmount();

        // Check bank cap
        uint256 cur = totalDeposited;
        if (cur + _amount > bankCap) revert ExceedsBankCap(bankCap - cur, _amount);

        // Effects
        balances[_from] += _amount;
        depositsCount[_from] += 1;
        totalDepositsCount += 1;
        totalDeposited += _amount;

        emit Deposit(_from, _amount, balances[_from], block.timestamp);
    }

    /// @notice Envía ETH de forma segura usando call
    function _safeSend(address payable to, uint256 amount) private {
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed(to, amount);
    }

    /* ========== VIEWS ========== */

    /// @notice Retorna el balance interno de una cuenta
    /// @param who dirección a consultar
    /// @return balance en wei
    function getBalance(address who) external view returns (uint256) {
        return balances[who];
    }

    /// @notice Retorna el espacio restante (wei) en el bankCap
    function remainingBankCap() external view returns (uint256) {
        if (totalDeposited >= bankCap) return 0;
        return bankCap - totalDeposited;
    }

    /* ========== RECEIVE / FALLBACK ========== */

    receive() external payable {
        _handleDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        _handleDeposit(msg.sender, msg.value);
    }

    /* ========== OPTIONAL ADMIN ========== */

    /// @notice Permite al owner rescatar ETH accidentalmente enviados (uso cuidadoso)
    function rescue(address payable to, uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmount();
        uint256 contractBal = address(this).balance;
        if (amount > contractBal) revert InsufficientBalance(address(this), contractBal, amount);
        _safeSend(to, amount);
    }
}

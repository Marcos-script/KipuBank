# KipuBank

## Descripción

KipuBank es un **banco simple en Solidity** que permite a los usuarios:

- Depositar ETH en una bóveda personal.  
- Retirar fondos respetando un **límite máximo por transacción**.  
- Controlar el límite global de depósitos del banco.  

El contrato aplica buenas prácticas de seguridad:  
- Uso de errores personalizados (`WithdrawLimitExceeded`, `DepositLimitExceeded`, etc.).  
- Patrón checks-effects-interactions.  
- Funciones `payable` y `view` correctamente implementadas.  
- Eventos para cada depósito y retiro.  

---

## Despliegue

1. Abrir [Remix IDE](https://remix.ethereum.org).  
2. Compilar el contrato `KipuBank.sol` con **Solidity 0.8.20** y **EVM Version: Shanghai**.  
3. Seleccionar la pestaña **Deploy & Run Transactions**:  
   - Environment: `Injected Provider - MetaMask`  
   - Conectar la wallet de MetaMask a la **testnet Sepolia**  
4. En los campos del constructor:  
   - `_withdrawLimit`: `1000000000000000000` (1 ETH)  
   - `_bankCap`: `10000000000000000000` (10 ETH)  
5. Hacer click en **Deploy** y confirmar la transacción en MetaMask.  

---

## Cómo interactuar

### Deposit

- Función: `deposit()`  
- Tipo: `payable`  
- Ingresar el **monto en wei** en el campo **Value (Ether)** arriba del botón `deposit()` en Remix.  
  - Ejemplo: 0.01 ETH → `10000000000000000` wei  
- Confirmar la transacción en MetaMask.  
- Se actualizará tu saldo y `totalDeposited`.  

### Withdraw

- Función: `withdraw(uint256 _amount)`  
- `_amount` en wei, no mayor a tu balance ni al `withdrawLimit`.  
- Confirmar la transacción en MetaMask.  
- Tu balance se actualizará y recibirás el ETH en tu wallet.  

### Consultar balance

- Función: `getBalance(address _user)`  
- Devuelve el saldo de cualquier usuario en wei.  

### Eventos

- `Deposit(address indexed user, uint256 amount)`  
- `Withdraw(address indexed user, uint256 amount)`  

---

## Dirección del contrato desplegado

- Sepolia Testnet: `0xA5eC33B56744C1aC17d1AAEaB12Ec3821BB1DEcC`  
- Verificado en SepoliaScan: [https://sepolia.etherscan.io/address/0xA5eC33B56744C1aC17d1AAEaB12Ec3821BB1DEcC](https://sepolia.etherscan.io/address/0xA5eC33B56744C1aC17d1AAEaB12Ec3821BB1DEcC)  

---

## Estructura del repositorio


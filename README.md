# KipuBank

## Descripción

KipuBank es un contrato inteligente desarrollado en Solidity que simula un banco descentralizado donde los usuarios pueden depositar y retirar ETH de manera segura dentro de una bóveda personal.  
El contrato incorpora buenas prácticas de seguridad, errores personalizados y una estructura de código clara y mantenible, siguiendo las convenciones del ecosistema Web3 moderno.

Este proyecto fue desarrollado como parte del TP2 - Módulo 2 de Desarrollo Web3, con el objetivo de integrar teoría, práctica y estándares profesionales en el despliegue de smart contracts.

## Funcionalidades Principales

- Depósitos: los usuarios pueden enviar ETH a su propia bóveda.
- Retiros: los usuarios pueden retirar fondos respetando un límite máximo por transacción.
- Capacidad total del banco: el contrato impone un tope global (`bankCap`) de fondos que puede recibir.
- Registros internos: se lleva control del número de depósitos y retiros realizados.
- Errores personalizados: asegura que los límites se respeten mediante revertencias claras y seguras.
- Eventos emitidos: cada depósito y retiro exitoso genera un evento en la blockchain.
- Seguridad: sigue el patrón Checks-Effects-Interactions y emplea transferencias seguras de ETH.
- Documentación NatSpec: todas las funciones, errores y variables incluyen comentarios de documentación.

## Variables Principales

| Tipo | Nombre | Descripción |
|------|---------|-------------|
| `immutable uint256` | `perTxLimit` | Límite máximo de retiro por transacción |
| `immutable uint256` | `bankCap` | Capacidad total máxima del banco |
| `mapping(address => uint256)` | `balances` | Registra los fondos de cada usuario |
| `uint256` | `totalDeposited` | Monto total depositado en el banco |
| `uint256` | `totalWithdrawn` | Monto total retirado del banco |

## Instrucciones de Despliegue

1. Abrir Remix IDE: [https://remix.ethereum.org](https://remix.ethereum.org)

2. Compilar el contrato:
   - Archivo: `KipuBank.sol`
   - Compilador: `0.8.20`
   - EVM Version: `Shanghai`
   - License: `MIT`

3. Ir a la pestaña “Deploy & Run Transactions”:
   - Environment: `Injected Provider - MetaMask`
   - Account: dirección de tu cuenta en Sepolia Testnet
   - Contract: `KipuBank`

4. Completar los parámetros del constructor:
_withdrawLimit: 1000000000000000000 // 1 ETH
_bankCap: 5000000000000000000 // 5 ETH

5. Hacer clic en “Deploy” y confirmar en MetaMask.

6. Dirección del contrato desplegado:
0x071C7A11d33dD0AF24c838063e8D87C8675e6cf5


7. Verificar el contrato en Etherscan:
[https://sepolia.etherscan.io/address/0x071C7A11d33dD0AF24c838063e8D87C8675e6cf5](https://sepolia.etherscan.io/address/0x071C7A11d33dD0AF24c838063e8D87C8675e6cf5)
   - Compiler: 0.8.20
   - License: MIT
   - EVM: Shanghai

## Cómo Interactuar con el Contrato

### Depositar ETH
- Función: `deposit()`
- Tipo: `external payable`
- Parámetro: ninguno
- Instrucciones:
  1. Ingresar el valor a depositar en el campo “Value” (en wei) sobre el botón `deposit()` en Remix.
  2. Ejemplo: 0.1 ETH → 100000000000000000 wei
  3. Hacer clic en `deposit()`.
  4. Confirmar la transacción en MetaMask.
- Evento emitido: `Deposit(address indexed user, uint256 amount)`

### Retirar ETH
- Función: `withdraw(uint256 _amount)`
- Tipo: `external`
- Parámetro: `_amount` → cantidad a retirar (en wei)
- Restricciones:
  - `_amount` ≤ tu balance personal.
  - `_amount` ≤ `perTxLimit`.
- Instrucciones:
  1. Ingresar el monto deseado en el campo `_amount`.
  2. Hacer clic en `withdraw`.
  3. Confirmar en MetaMask.
- Evento emitido: `Withdraw(address indexed user, uint256 amount)`

### Consultar Balance
- Función: `getBalance(address _user)`
- Tipo: `external view returns (uint256)`
- Instrucciones:
  1. Ingresar una dirección Ethereum.
  2. Hacer clic en `call`.
  3. Devuelve el saldo del usuario en wei.

## Errores Personalizados

| Error | Descripción |
|--------|-------------|
| `ZeroAmount()` | Se intenta depositar o retirar un monto igual a cero. |
| `InsufficientBalance(address who, uint256 available, uint256 requested)` | El usuario intenta retirar más de su balance. |
| `ExceedsBankCap(uint256 available, uint256 attempted)` | Se excede la capacidad total (`bankCap`) del banco. |
| `ExceedsPerTxLimit(uint256 requested, uint256 limit)` | Se intenta retirar más que el límite por transacción. |
| `TransferFailed(address to, uint256 amount)` | La transferencia externa de ETH falló. |
| `Reentrancy()` | Se detectó un intento de reentrancy. |

## Patrones y Buenas Prácticas Utilizadas

- Checks → Effects → Interactions
- Errores personalizados en lugar de strings en `require`.
- Uso de modifiers para validaciones de acceso y límites.
- Variables `immutable` y `constant` correctamente aplicadas.
- Eventos para trazabilidad.
- Funciones privadas y externas bien diferenciadas.
- Comentarios NatSpec para documentación técnica.

## Dirección del Contrato

Red: Sepolia Testnet  
Contrato desplegado: `0x071C7A11d33dD0AF24c838063e8D87C8675e6cf5`  
Ver en Etherscan: [https://sepolia.etherscan.io/address/0x071C7A11d33dD0AF24c838063e8D87C8675e6cf5](https://sepolia.etherscan.io/address/0x071C7A11d33dD0AF24c838063e8D87C8675e6cf5)

## Licencia

Este proyecto está bajo la licencia MIT. Se puede usar, modificar y distribuir libremente citando su autoría original.

Desarrollado por: Marcos del Río
Trabajo Práctico N°2 – Desarrollo Web3 (Módulo 2)  
Smart Contract: KipuBank.sol

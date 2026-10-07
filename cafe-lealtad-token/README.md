# Café Andino en Blockchain – Smart Contracts ERC20 y ERC721

Proyecto "Desarrollando un prototipo en la red Blockchain" (Diseño de Soluciones Blockchain – AA2).
Caso de negocio: una cafetería real (ej. "Café Andino", Lima, Perú) que quiere fidelizar a sus clientes.

## Contratos

| Archivo | Estándar | Función |
|---|---|---|
| `contracts/CafeLealtadToken.sol` | **ERC20** | Puntos de lealtad (CLT) que se ganan comprando y se canjean por premios |
| `contracts/CafeMembresiaNFT.sol` | **ERC721** | Membresía única del club (Bronce, Plata, Oro) con descuento según nivel |

## 1. CafeLealtadToken (ERC20)

**Problema:** las tarjetas de puntos en papel se pierden, se falsifican y el cliente no puede verificar su saldo.

- **1 CLT = 1 punto** (0 decimales).
- `rewardPurchase(cliente, montoSoles)`: el dueño entrega puntos por cada sol gastado.
- `redeem(idPremio)`: el cliente canjea puntos por un premio (se queman).
- Los puntos son transferibles y auditables on-chain.
- Suministro máximo: 1 000 000 puntos (`ERC20Capped`).
- Funciones del dueño: `setPointsPerSol`, `setReward`.

## 2. CafeMembresiaNFT (ERC721)

**Problema:** las membresías en tarjeta o en una base de datos del negocio se duplican, se pierden y no pueden transferirse de forma segura. El cliente no tiene una prueba verificable de su nivel.

- Cada membresía es un **NFT único** con dueño y metadatos propios (`tokenURI`).
- Niveles y descuento: Bronce 5 %, Plata 10 %, Oro 20 %.
- `emitirMembresia(socio, nivel, uri)`: el negocio emite la membresía.
- `subirNivel(tokenId, nuevoNivel, nuevaUri)`: premia al socio fiel (solo se puede subir).
- `revocarMembresia(tokenId)`: el negocio puede quemarla en caso de fraude.
- `descuentoDeMembresia(tokenId)` y `ownerOf(tokenId)`: cualquiera puede verificar nivel y dueño.
- El socio puede regalar o vender su membresía (transferencia ERC721).

## Tecnologías
- Solidity ^0.8.20
- OpenZeppelin Contracts v5 (`ERC20`, `ERC20Burnable`, `ERC20Capped`, `ERC721`, `ERC721URIStorage`, `Ownable`)

## Cómo probarlos (Remix)
1. Abrir [remix.ethereum.org](https://remix.ethereum.org) y crear un archivo por contrato con el contenido de la carpeta `contracts/`.
2. Compilar con Solidity 0.8.20 o superior (Remix descarga OpenZeppelin con los `import`).
3. En *Deploy*, indicar tu dirección como `initialOwner`.
4. Pruebas sugeridas:
   - ERC20: `rewardPurchase` → `balanceOf` → `redeem(1)`.
   - ERC721: `emitirMembresia` → `ownerOf(1)` → `descuentoDeMembresia(1)` → `subirNivel`.
5. Idealmente desplegar en una testnet como Sepolia.

## Licencia
MIT

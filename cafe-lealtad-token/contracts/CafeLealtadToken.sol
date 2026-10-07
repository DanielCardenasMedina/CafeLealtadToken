// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CafeLealtadToken (CLT)
 * @notice Token ERC20 de fidelización para una cafetería real (ej. "Café Andino", Lima, Perú).
 *
 * PROBLEMA DEL NEGOCIO:
 *  - Las tarjetas de puntos en papel se pierden, se falsifican y no se pueden transferir.
 *  - El cliente no puede verificar cuántos puntos tiene ni que el negocio no los modifique.
 *
 * SOLUCIÓN:
 *  - 1 CLT = 1 punto de lealtad (0 decimales).
 *  - Por cada S/ 1 de compra el cliente recibe `pointsPerSol` puntos (los emite el negocio).
 *  - El cliente canjea sus puntos por productos: el contrato los quema (burn).
 *  - Los puntos son transferibles (regalar a un amigo) y su saldo es auditable on-chain.
 *  - Suministro máximo limitado (cap) para evitar inflación de puntos.
 */
contract CafeLealtadToken is ERC20, ERC20Burnable, ERC20Capped, Ownable {
    /// @dev Puntos entregados por cada sol gastado.
    uint256 public pointsPerSol = 1;

    /// @dev Catálogo de premios: id => costo en puntos (0 = premio no disponible).
    mapping(uint256 => uint256) public rewardCost;
    /// @dev Nombre legible del premio (ej. "Café americano gratis").
    mapping(uint256 => string) public rewardName;

    event PurchaseRewarded(address indexed customer, uint256 amountSoles, uint256 pointsMinted);
    event RewardConfigured(uint256 indexed rewardId, string name, uint256 cost);
    event RewardRedeemed(address indexed customer, uint256 indexed rewardId, uint256 pointsBurned);
    event PointsPerSolChanged(uint256 oldValue, uint256 newValue);

    /**
     * @param initialOwner Dirección del dueño/administrador de la cafetería.
     */
    constructor(address initialOwner)
        ERC20("Cafe Lealtad Token", "CLT")
        ERC20Capped(1_000_000) // máximo 1 000 000 de puntos en circulación
        Ownable(initialOwner)
    {
        // Premios iniciales de ejemplo
        _setReward(1, "Cafe americano gratis", 50);
        _setReward(2, "Postre del dia gratis", 80);
        _setReward(3, "Desayuno completo gratis", 150);
    }

    /// @notice Los puntos son enteros: 1 CLT = 1 punto.
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    // ------------------------------------------------------------------
    // Funciones del negocio (solo el dueño)
    // ------------------------------------------------------------------

    /// @notice Registra una compra y entrega puntos al cliente.
    /// @param customer Billetera del cliente.
    /// @param amountSoles Monto de la compra en soles (entero).
    function rewardPurchase(address customer, uint256 amountSoles) external onlyOwner {
        require(customer != address(0), "Cliente invalido");
        require(amountSoles > 0, "Monto debe ser > 0");
        uint256 points = amountSoles * pointsPerSol;
        _mint(customer, points);
        emit PurchaseRewarded(customer, amountSoles, points);
    }

    /// @notice Cambia cuántos puntos se otorgan por sol (promociones, ej. x2).
    function setPointsPerSol(uint256 newValue) external onlyOwner {
        require(newValue > 0, "Debe ser > 0");
        emit PointsPerSolChanged(pointsPerSol, newValue);
        pointsPerSol = newValue;
    }

    /// @notice Crea o actualiza un premio del catálogo (cost = 0 lo desactiva).
    function setReward(uint256 rewardId, string calldata name, uint256 cost) external onlyOwner {
        _setReward(rewardId, name, cost);
    }

    // ------------------------------------------------------------------
    // Funciones del cliente
    // ------------------------------------------------------------------

    /// @notice El cliente canjea un premio: se queman los puntos necesarios.
    function redeem(uint256 rewardId) external {
        uint256 cost = rewardCost[rewardId];
        require(cost > 0, "Premio no disponible");
        require(balanceOf(msg.sender) >= cost, "Puntos insuficientes");
        _burn(msg.sender, cost);
        emit RewardRedeemed(msg.sender, rewardId, cost);
    }

    // ------------------------------------------------------------------
    // Internas
    // ------------------------------------------------------------------

    function _setReward(uint256 rewardId, string memory name, uint256 cost) internal {
        rewardName[rewardId] = name;
        rewardCost[rewardId] = cost;
        emit RewardConfigured(rewardId, name, cost);
    }

    /// @dev Requerido por Solidity al combinar ERC20 con ERC20Capped (OpenZeppelin v5).
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Capped)
    {
        super._update(from, to, value);
    }
}

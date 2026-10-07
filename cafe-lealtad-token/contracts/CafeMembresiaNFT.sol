// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CafeMembresiaNFT (CAM)
 * @notice Token ERC721 que representa una membresía única del club de clientes
 *         de una cafetería real (ej. "Café Andino", Lima, Perú).
 *
 * PROBLEMA DEL NEGOCIO:
 *  - Las membresías en tarjeta física o en una base de datos del negocio se
 *    duplican, se pierden y no pueden revenderse ni regalarse de forma segura.
 *  - El cliente no tiene prueba verificable de su nivel ni de sus beneficios.
 *
 * SOLUCIÓN CON ERC721:
 *  - Cada membresía es un NFT único (tokenId) con su propio dueño y metadatos.
 *  - Tres niveles: Bronce (5 %), Plata (10 %) y Oro (20 % de descuento).
 *  - El negocio emite la membresía y puede subir de nivel a un socio fiel.
 *  - El socio puede transferir o regalar su membresía (estándar ERC721).
 *  - Cualquiera puede verificar on-chain quién es el dueño y qué nivel tiene.
 */
contract CafeMembresiaNFT is ERC721, ERC721URIStorage, Ownable {
    enum Nivel { Bronce, Plata, Oro }

    uint256 private _nextTokenId = 1;

    /// @dev Nivel actual de cada membresía.
    mapping(uint256 => Nivel) public nivelDe;

    /// @dev Porcentaje de descuento por nivel (Bronce 5, Plata 10, Oro 20).
    mapping(Nivel => uint8) public descuentoPorNivel;

    event MembresiaEmitida(address indexed socio, uint256 indexed tokenId, Nivel nivel);
    event NivelSubido(uint256 indexed tokenId, Nivel nivelAnterior, Nivel nivelNuevo);
    event MembresiaRevocada(uint256 indexed tokenId);

    /**
     * @param initialOwner Dirección del dueño/administrador de la cafetería.
     */
    constructor(address initialOwner)
        ERC721("Cafe Andino Membresia", "CAM")
        Ownable(initialOwner)
    {
        descuentoPorNivel[Nivel.Bronce] = 5;
        descuentoPorNivel[Nivel.Plata] = 10;
        descuentoPorNivel[Nivel.Oro] = 20;
    }

    // ------------------------------------------------------------------
    // Funciones del negocio (solo el dueño)
    // ------------------------------------------------------------------

    /// @notice Emite una membresía nueva a un cliente.
    /// @param socio Billetera del cliente.
    /// @param nivel Nivel inicial de la membresía.
    /// @param uri Enlace a los metadatos (JSON con nombre, imagen, beneficios), ej. ipfs://...
    /// @return tokenId Identificador de la membresía emitida.
    function emitirMembresia(address socio, Nivel nivel, string calldata uri)
        external
        onlyOwner
        returns (uint256 tokenId)
    {
        tokenId = _nextTokenId++;
        nivelDe[tokenId] = nivel;
        _safeMint(socio, tokenId);
        _setTokenURI(tokenId, uri);
        emit MembresiaEmitida(socio, tokenId, nivel);
    }

    /// @notice Sube de nivel una membresía (solo se puede subir, no bajar).
    /// @param tokenId Membresía a mejorar.
    /// @param nuevoNivel Nivel superior al actual.
    /// @param nuevaUri Nuevos metadatos acordes al nivel (imagen de la tarjeta, etc.).
    function subirNivel(uint256 tokenId, Nivel nuevoNivel, string calldata nuevaUri)
        external
        onlyOwner
    {
        _requireOwned(tokenId);
        Nivel actual = nivelDe[tokenId];
        require(nuevoNivel > actual, "Solo se puede subir de nivel");
        nivelDe[tokenId] = nuevoNivel;
        _setTokenURI(tokenId, nuevaUri);
        emit NivelSubido(tokenId, actual, nuevoNivel);
    }

    /// @notice Revoca (quema) una membresía, por ejemplo en caso de fraude.
    function revocarMembresia(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        delete nivelDe[tokenId];
        emit MembresiaRevocada(tokenId);
    }

    // ------------------------------------------------------------------
    // Consultas (cualquiera puede verificar)
    // ------------------------------------------------------------------

    /// @notice Porcentaje de descuento que da una membresía.
    function descuentoDeMembresia(uint256 tokenId) external view returns (uint8) {
        _requireOwned(tokenId);
        return descuentoPorNivel[nivelDe[tokenId]];
    }

    /// @notice Total de membresías emitidas históricamente.
    function totalEmitidas() external view returns (uint256) {
        return _nextTokenId - 1;
    }

    // ------------------------------------------------------------------
    // Overrides requeridos por Solidity (OpenZeppelin v5)
    // ------------------------------------------------------------------

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Le indico al sistema que este código es de uso libre

pragma solidity ^0.8.20;
// Le digo al programa que versión voy a usar para que no haya errores

contract FondoColectivo {
// Este es el nombre de mi contrato, es como ponerle nombre a un programa

    // ── Aquí declaro la información que va a recordar el contrato ─────────────

    address public administrador;
    // Guardo la dirección de quien desplegó el contrato
    // Esa persona será la única con permiso para sacar dinero

    mapping(address => uint256) public contribuciones;
    // Creo una lista donde cada persona tiene anotado cuánto ha metido
    // Es como una tabla de Excel: columna 1 = persona, columna 2 = su aporte

    uint256 public fondoTotal;
    // Esta variable lleva la cuenta de todo el dinero que hay acumulado
    // Aumenta cada vez que alguien hace un depósito

    // ── Avisos que quedan grabados para siempre en la blockchain ─────────────

    event NuevoDeposito(address indexed quien, uint256 cuanto);
    // Cada vez que alguien deposita, queda un registro público de eso
    // Se puede consultar en Etherscan como un historial

    event RetiroRealizado(address indexed beneficiario, uint256 cuanto);
    // Igual pero para los retiros que autoriza el administrador
    // Así todo queda transparente y nadie puede negar que se hizo

    // ── Un candado de seguridad para proteger funciones importantes ──────────

    modifier soloAdministrador() {
        require(
            msg.sender == administrador,
            "No tienes permiso para hacer esto"
        );
        // Antes de ejecutar cualquier función protegida, verifico que
        // quien la llama sea el administrador. Si no lo es, se cancela todo
        _;
        // Aquí continúa ejecutándose el resto de la función
    }

    // ── Esto se ejecuta una única vez cuando creo el contrato ────────────────

    constructor() {
        administrador = msg.sender;
        // La persona que publica el contrato queda guardada como administrador
        // Nadie más puede cambiar esto después
    }

    // ── Cualquier persona puede usar esta función para meter dinero ──────────

    function depositar() external payable {
        // Con payable le digo al contrato que esta función acepta ETH
        // Con external indico que la llaman desde afuera del contrato

        require(msg.value > 0, "Tienes que enviar algo de ETH");
        // Si alguien intenta depositar cero, el contrato lo bloquea
        // msg.value es la cantidad de ETH que mandaron

        contribuciones[msg.sender] += msg.value;
        // Le sumo a esa persona lo que acaba de depositar
        // Si es la primera vez que deposita, empieza desde cero y se suma

        fondoTotal += msg.value;
        // También actualizo el total general del fondo

        emit NuevoDeposito(msg.sender, msg.value);
        // Genero el aviso para que quede en el historial de la blockchain
    }

    // ── Solo el administrador puede usar esta función para sacar dinero ──────

    function autorizarRetiro(
        address payable receptor,
        // La dirección de la persona que va a recibir el dinero
        uint256 cantidad
        // Cuánto dinero se le va a enviar
    ) external soloAdministrador {
        // El candado de seguridad bloquea esta función si no eres administrador

        require(cantidad > 0, "La cantidad tiene que ser mayor a cero");
        // Me aseguro de que tenga sentido el retiro

        require(cantidad <= address(this).balance, "No hay suficiente dinero");
        // Reviso que el contrato tenga ese dinero antes de intentar enviarlo
        // address(this) es como decir "la dirección de este contrato"

        (bool transferido, ) = receptor.call{value: cantidad}("");
        // Aquí envío el dinero a la dirección que eligió el administrador
        // Es la manera recomendada y más segura de hacer transferencias

        require(transferido, "El envío del dinero falló");
        // Si por alguna razón el envío no funcionó, cancelo todo

        emit RetiroRealizado(receptor, cantidad);
        // Dejo constancia del retiro en el historial público
    }

    // ── Función para ver cuánto dinero tiene el contrato en este momento ─────

    function verSaldo() external view returns (uint256) {
        // Con view indico que solo estoy consultando, no modificando nada
        // Por eso no cobra gas al usarla desde afuera
        return address(this).balance;
        // Devuelve el saldo actual del contrato en wei
    }
}
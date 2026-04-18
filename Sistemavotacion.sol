// License 
//-SPDX-License-Identifier: LGPL-3.0-only 
// Sistema de votación con Whitelist y Tiempo Límite
// Solo el owner puede registrar candidatos y votantes. Votar cuesta 0.01ETH.
//Solidity Version 
pragma solidity 0.8.34; 

//Contrato
contract SistemaVotacion {

//Variables 
 address public owner;
 uint256 public votacionFin; //timestap de cierre 
 uint256 public constant Precio_voto= 0.01 ether;

//Mapping 
mapping (uint256 => Candidato) public candidatos; 
mapping (address => bool) public whitelist;
mapping (address => bool) public haVotado;

uint256 public totalCandidatos; 
//Structs 
struct Candidato {
    string nombre;
    uint256 votos;
}
//Modifiers 
modifier soloOwner () {
    if (msg.sender != owner) revert ("No eres el owner");
    _;
}
modifier soloWhitelist() {
    if (!whitelist [msg.sender]) revert ("No estas autorizado para votar");
    _;
}
modifier votacionAbierta (){
    if (block.timestamp >= votacionFin) revert ("La votacion ha terminado");
    _;
}
modifier votacionCerrada (){
    if (block.timestamp < votacionFin) revert ("La votacion sigue abierta");
    _;
}
modifier noHaVotado(){
    if (haVotado [msg.sender]) revert ("Ya has votado");
    _;
}
modifier candidatoValido (uint256 candidatoId_) {
    if (candidatoId_ ==0 || candidatoId_ > totalCandidatos) revert ("Candidato no existe");
    _;
}

//Constructor 
// parm duracionSegundos_. Cuantos segundos estará abierta la votación
constructor (uint256 duracionSegundos_){
    owner= msg.sender;
    votacionFin= block.timestamp + duracionSegundos_; 
}
//Events 
event CandidatoRegistrado (uint256 indexed id, string nombre);
event VotanteAutorizado (address indexed votante);
event VotoEmitido (address indexed votante, uint256 indexed candidatoId);
event FondosRetirados (address indexed owner, uint256 cantidad);

//Funciones
//Funciones del owner

//Registra un nuevo candidato (solo durante votacion abierta)
function registrarCandidato (string calldata nombre_) external soloOwner votacionAbierta {
    totalCandidatos++;
    candidatos [totalCandidatos] =Candidato ({nombre: nombre_, votos:0});
    emit CandidatoRegistrado(totalCandidatos, nombre_);
}
//Autoriza a un votante
function autorizarVotante(address votante_) external soloOwner votacionAbierta {
    whitelist[votante_]= true;
    emit VotanteAutorizado(votante_);
}
// Autoriza multiples votantes de una vez 
function autorizarVotantes (address []calldata votantes_) external soloOwner votacionAbierta{
    for (uint256 i=0; i< votantes_.length; i++) {
        whitelist [votantes_[i]] = true;
        emit VotanteAutorizado(votantes_[i]);
    }
}

//Retira los fondos acumulados (solo tras cerrar la votación)
function retirarFondos() external soloOwner votacionCerrada {
    uint256 balance = address(this).balance;
    if (balance ==0) revert ("No hay fondos");
    (bool ok, ) = owner.call {value:balance}("");
    if (!ok) revert ("Transferencia fallida");
    emit FondosRetirados(owner, balance);
}

//Función de voto
//Emite un voto. Requiere pagar exactamente Precio_Voto (0.01 ETH).
function votar (uint256 candidatoId_) external payable soloWhitelist votacionAbierta noHaVotado candidatoValido (candidatoId_) {
    if (msg.value != Precio_voto) revert ("Debes enviar exactamente 0.01 ETH");
    haVotado[msg.sender]= true;
    candidatos[candidatoId_].votos++;
    emit VotoEmitido (msg.sender, candidatoId_);
}

//Funciones de consulta
//Devuelve el candidato ganador (en caso de epate, el menor id)
function ganador() external view votacionCerrada returns (string memory nombre_, uint256 votos_) {
    if (totalCandidatos==0) revert ("No hay candidatos");
    uint256 maxVotos=0;
    uint256 ganadorId=0;
    for (uint256 i=1; i<= totalCandidatos; i++) {
        if (candidatos[i].votos > maxVotos) {
            maxVotos= candidatos[i].votos;
            ganadorId=i;
        }
    }
    nombre_= candidatos [ganadorId].nombre;
    votos_=candidatos[ganadorId].votos;
}
//Consulta los votos de un candidato concreto 
function consultarCandidato(uint256 candidatoId_) external view candidatoValido(candidatoId_) returns (string memory nombre_,uint256 votos_) {
    nombre_= candidatos[candidatoId_].nombre;
    votos_= candidatos[candidatoId_].votos;
}

// Tiempo restante en segundos (0 si ya cerró)
function tiempoRestante() external view returns (uint256) {
    if (block.timestamp >= votacionFin) return 0;
    return votacionFin - block.timestamp;
}
// Balance acumulado en el contrato
function balanceContrato() external view returns (uint256) {
    return address(this).balance;
}

}
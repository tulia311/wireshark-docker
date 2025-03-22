
// Définition de la fonction updatePacketCount
function updatePacketCount(count) {
    document.getElementById('packet-count').innerText = count;
}

// Connexion au flux SSE
const eventSource = new EventSource('/capture');
let packetCount = 0;

eventSource.onmessage = function (event) {
    // Incrémenter le compteur de paquets
    packetCount++;
    updatePacketCount(packetCount);

    // Afficher les données du paquet (optionnel)
    console.log("Packet received:", event.data);
};
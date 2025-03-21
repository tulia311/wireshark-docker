from flask import Flask, Response, render_template, request, jsonify
import subprocess
import json
import os
import threading
import time
from typing import Dict, List, Optional, Generator

app = Flask(__name__)

# Variable globale pour stocker le processus de capture
capture_process: Optional[subprocess.Popen] = None
capture_lock = threading.Lock()

@app.route('/')
def index() -> str:
    """
    Affiche la page d'accueil de l'interface web Wireshark.
    
    Returns:
        str: Template HTML rendu
    """
    return render_template('index.html')

@app.route('/capture')
def capture() -> Response:
    """
    Crée un flux d'événements serveur (Server-Sent Events) pour envoyer
    les données de capture en temps réel au navigateur.
    
    Returns:
        Response: Flux SSE des paquets capturés
    """
    def generate() -> Generator[str, None, None]:
        process = subprocess.Popen(
            ['tshark', '-i', 'any', '-T', 'json'],
            stdout=subprocess.PIPE,
            universal_newlines=True
        )
        
        for line in process.stdout:
            yield f"data: {line}\n\n"

    return Response(generate(), mimetype='text/event-stream')

@app.route('/api/interfaces', methods=['GET'])
def get_interfaces() -> Response:
    """
    Récupère la liste des interfaces réseau disponibles.
    
    Returns:
        Response: Liste des interfaces au format JSON
    """
    try:
        # Exécute tshark pour lister les interfaces
        result = subprocess.run(
            ['tshark', '-D'],
            capture_output=True,
            text=True,
            check=True
        )
        
        interfaces = []
        for line in result.stdout.splitlines():
            parts = line.split('. ', 1)
            if len(parts) == 2:
                interface_info = parts[1].split(' (', 1)
                name = interface_info[0]
                description = interface_info[1][:-1] if len(interface_info) > 1 else ""
                interfaces.append({"name": name, "description": description})
        
        return jsonify(interfaces)
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Erreur lors de la récupération des interfaces: {e}"}), 500

@app.route('/api/start_capture', methods=['POST'])
def start_capture() -> Response:
    """
    Démarre une capture Wireshark avec les paramètres fournis.
    
    Returns:
        Response: Résultat de l'opération au format JSON
    """
    global capture_process
    
    with capture_lock:
        if capture_process:
            return jsonify({"error": "Une capture est déjà en cours"}), 400
        
        try:
            data = request.json
            interface = data.get('interface', 'any')
            capture_filter = data.get('filter', '')
            
            cmd = ['tshark', '-i', interface, '-T', 'json']
            if capture_filter:
                cmd.extend(['-f', capture_filter])
            
            capture_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            return jsonify({"success": True, "message": "Capture démarrée"})
        except Exception as e:
            return jsonify({"error": f"Erreur lors du démarrage de la capture: {str(e)}"}), 500

@app.route('/api/stop_capture', methods=['POST'])
def stop_capture() -> Response:
    """
    Arrête la capture Wireshark en cours.
    
    Returns:
        Response: Résultat de l'opération au format JSON
    """
    global capture_process
    
    with capture_lock:
        if not capture_process:
            return jsonify({"error": "Aucune capture en cours"}), 400
        
        try:
            capture_process.terminate()
            capture_process.wait(timeout=5)
            capture_process = None
            return jsonify({"success": True, "message": "Capture arrêtée"})
        except Exception as e:
            return jsonify({"error": f"Erreur lors de l'arrêt de la capture: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
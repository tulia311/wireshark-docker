# Interface Web Wireshark Docker

![Wireshark Logo](./wireshark.png)

Ce projet fournit une interface web Dockerisée pour Wireshark permettant d'analyser le trafic réseau en temps réel via votre navigateur.

## Structure du projet

```
wireshark-docker/
├── Dockerfile
├── src/
│   ├── app.py
│   └── templates/
│       └── index.html
├── .gitignore
└── README.md
```

## Fonctionnalités

- Interface web responsive
- Capture de paquets en temps réel
- Sélection d'interface réseau
- Filtrage des paquets
- Visualisation détaillée des captures
- Support de TShark

## Pour commencer

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/tulia311/wireshark.git
   cd wireshark
   ```

2. **Construire l'image Docker** :
   ```bash
   docker build -t wireshark .
   ```

3. **Exécuter le conteneur** :
   ```bash
   docker run --name wireshark \
     --net=host \
     --privileged \
     -p 8080:8080 \
     wireshark
   ```

4. **Accéder à l'interface web** :
   Ouvrez votre navigateur et accédez à `http://localhost:8080`

## Configuration

Vous pouvez personnaliser le comportement via des variables d'environnement :

```bash
docker run --name wireshark \
  --net=host \
  --privileged \
  -p 8080:8080 \
  -e CAPTURE_INTERFACE=eth0 \
  -e CAPTURE_FILTER="port 80" \
  wireshark
```

Variables disponibles :
- `CAPTURE_INTERFACE` : Interface réseau à surveiller (défaut: "any")
- `CAPTURE_FILTER` : Filtre de capture BPF (exemple: "port 80")

## Utilisation de l'interface web

1. **Sélection de l'interface** :
   - Choisissez l'interface réseau dans le menu déroulant
   - L'option "Toutes les interfaces" capture sur toutes les interfaces

2. **Contrôles de capture** :
   - Cliquez sur "Démarrer la capture" pour commencer
   - Cliquez sur "Arrêter la capture" pour terminer

3. **Visualisation** :
   - Les paquets s'affichent en temps réel
   - Chaque paquet montre :
     - Horodatage
     - Adresse source
     - Adresse destination
     - Protocoles utilisés

## Sécurité

**Important** : Ce conteneur nécessite des privilèges élevés pour la capture réseau.

### Recommandations de sécurité

1. **Isolation réseau** :
   - Utilisez des réseaux Docker dédiés
   - Limitez les interfaces réseau exposées
   - Configurez des règles de pare-feu strictes

2. **Authentification et autorisation** :
   - Implémentez une authentification forte (OAuth2, JWT)
   - Utilisez HTTPS avec des certificats valides
   - Définissez des rôles utilisateurs avec permissions limitées

3. **Configuration du conteneur** :
   ```bash
   docker run --name wireshark \
     --net=host \
     --security-opt=no-new-privileges \
     --cap-drop=ALL \
     --cap-add=NET_ADMIN \
     --cap-add=NET_RAW \
     -p 127.0.0.1:8080:8080 \
     wireshark
   ```

4. **Bonnes pratiques** :
   - Mettez régulièrement à jour l'image Docker
   - Surveillez les logs pour détecter les activités suspectes
   - Effectuez des audits de sécurité périodiques
   - Limitez l'accès aux fichiers de capture

## Exigences

- Docker
- Navigateur web moderne
- Accès réseau privilégié sur l'hôte

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
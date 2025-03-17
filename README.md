# Projet Docker Wireshark

![Wireshark Logo](./wireshark.png)

Ce projet fournit un environnement Dockerisé pour exécuter Wireshark et analyser les captures de paquets.

## Structure du projet

- **Dockerfile**: Contient les instructions pour construire l'image Docker pour Wireshark, y compris l'image de base, les dépendances et la configuration de l'environnement.
- **docker-compose.yml**: Configure les services Docker pour le projet, définissant les conteneurs, réseaux et volumes nécessaires pour exécuter Wireshark et ses dépendances.
- **.gitignore**: Spécifie les fichiers et répertoires à ignorer par Git, tels que les fichiers temporaires ou les dépendances qui ne doivent pas être suivis.

## Pour commencer

Pour commencer avec ce projet, suivez ces étapes :

1. **Cloner le dépôt** :
   ```
   git clone <repository-url>
   cd wireshark-docker
   ```

2. **Construire l'image Docker** :
   ```
   docker build -t wireshark-docker .
   ```

3. **Exécuter le conteneur Docker** :
   ```
   docker-compose up
   ```

4. **Analyser les captures de paquets** :
   Utilisez Wireshark pour analyser vos fichiers de capture de paquets.

## Exigences

- Docker
- Docker Compose

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.
FROM archlinux

# Installation des dépendances
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    wireshark-cli \
    wireshark-qt \
    python \
    python-pip \
    gcc \
    python-flask \
    gunicorn \
    python-werkzeug \
    libcap

# Définition de la variable DISPLAY
ENV DISPLAY=:0

# Changement d'utilisateur
USER root

# Création de l'utilisateur et configuration des permissions
RUN groupadd -f wireshark && \
    useradd -m -g wireshark wireshark && \
    setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap && \
    chown root:wireshark /usr/bin/dumpcap && \
    chmod 750 /usr/bin/dumpcap

# Création du répertoire de travail
WORKDIR /app

# Copie des fichiers nécessaires
COPY src/app.py /app/
COPY src/templates /app/templates/
COPY venv/ /app/venv/

# Configuration des permissions
RUN chown -R wireshark:wireshark /app && \
    chmod -R 755 /app && \
    chmod -R 775 /app/venv 

# Changement d'utilisateur
USER wireshark

# Exposition du port
EXPOSE 8080

# Logging
LABEL logging.driver="json-file"
LABEL logging.options.max-size="10m"
LABEL logging.options.max-file="3"

# Démarrage de l'application
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
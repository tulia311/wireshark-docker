FROM alpine:latest

# Installation des dépendances
RUN apk update && \
    apk add --no-cache \
    wireshark \
    python3 \
    py3-pip \
    tshark \
    gcc \
    musl-dev \
    python3-dev \
    libcap # Ajout de libcap pour setcap

# Installation des dépendances via apk
RUN apk add --no-cache \
    py3-flask \
    py3-gunicorn

# Création d'un utilisateur non-root et configuration des permissions
RUN adduser -S wireshark -G wireshark && \
    apk add --no-cache libcap && \
    setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap && \
    chown root:wireshark /usr/bin/dumpcap && \
    chmod 750 /usr/bin/dumpcap

# Création du répertoire de travail
WORKDIR /app

# Copie des fichiers nécessaires
COPY src/app.py /app/
COPY src/templates /app/templates/

# Configuration des permissions
RUN chown -R wireshark:wireshark /app && \
    chmod -R 755 /app

# Changement d'utilisateur
USER wireshark

# Exposition du port
EXPOSE 8080

# Démarrage de l'application
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
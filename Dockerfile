FROM alpine:latest

# Install Wireshark and its dependencies
RUN apk update && \
    apk add --no-cache wireshark

# Set the working directory
WORKDIR /app

# Ce snippet de Dockerfile copie le fichier de capture et le script d'analyse
# du répertoire 'src' dans le contexte de build vers le répertoire '/app'
# dans l'image Docker.
# Copier le fichier de capture et le script d'analyse
COPY src/capture.pcap /app/capture.pcap
COPY src/analyze.py /app/analyze.py

# Set the entry point to run tshark
ENTRYPOINT ["tshark", "-r", "/app/capture.pcap"]
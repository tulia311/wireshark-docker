FROM archlinux

# Mise à jour des dépôts et installation des dépendances
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    wireshark-qt \
    libcap \
    xorg-xauth \
    xcb-util-cursor \
    xcb-util-image \
    xcb-util-keysyms \
    pipewire \
    pipewire-jack \
    qt6-base \
    qt6-wayland \
    libxkbcommon-x11 \
    harfbuzz \
    freetype2 \
    mesa \
    libglvnd \
    ttf-dejavu

# Création d'un utilisateur non-root
RUN groupadd -f wireshark && \
    useradd -m -g wireshark -s /bin/bash wireshark_user && \
    setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap && \
    chmod 750 /usr/bin/dumpcap

# Variables d'environnement
ENV DISPLAY=:0
ENV ENV QT_QPA_PLATFORM=xcb
ENV XAUTHORITY=/home/wireshark_user/.Xauthority

WORKDIR /home/wireshark_user
USER wireshark_user

CMD ["wireshark"]
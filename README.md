![Wireshark Logo](./wireshark.png)

# 

---

# Configuration de Docker avec X11 sur Debian en Mode Multi-utilisateur

Ce rapport analyse la situation où un système Debian configuré en mode multi-utilisateur (sans interface graphique par défaut) tente d'exécuter des applications graphiques depuis des conteneurs Docker. Les erreurs d'affichage observées sont typiques lorsque X11 n'est pas correctement configuré ou activé.

## État actuel du système

La configuration actuelle du système Debian présente plusieurs caractéristiques importantes qui affectent la capacité à exécuter des applications graphiques:

### Niveau de démarrage et services X11

Le système est configuré pour démarrer en mode multi-utilisateur sans interface graphique par défaut, comme l'indique la commande `systemctl get-default` qui renvoie `multi-user.target`[^1_9]. Ceci est significatif car ce mode n'initialise pas automatiquement le serveur X11 nécessaire aux applications graphiques.

Plus problématique encore, le service x11-common est explicitement désactivé, étant lié symboliquement vers `/dev/null`[^1_9]. Cette configuration empêche le système de charger les composants X11 fondamentaux au démarrage. Le fichier `/dev/null` est utilisé comme "trou noir" dans les systèmes Unix et Linux - tout ce qui y est écrit est simplement ignoré et détruit sans consommer de ressources[^1_9].

### Erreurs de session X

Les erreurs dans le fichier `~/.xsession-errors` confirment le problème:

```
Xsession: X session started for root at dim. 23 mars 2025 16:34:25 CET
dbus-update-activation-environment: setting DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/0/bus
xrdb: Can't open display ''
xhost: unable to open display ""
dbus-update-activation-environment: setting GTK_MODULES=gail:atk-bridge
dbus-update-activation-environment: setting QT_ACCESSIBILITY=1
```

Ces messages d'erreur indiquent clairement que:

- Une session X a tenté de démarrer pour l'utilisateur root
- Le système ne peut pas trouver de display X11 valide
- Les commandes `xrdb` et `xhost` échouent car aucun serveur X n'est disponible[^1_5][^1_7]


## Problématique Docker et X11

### Défis spécifiques à Docker

L'utilisation de Docker avec des applications graphiques pose des défis particuliers:

1. **Isolation des conteneurs**: Par défaut, les conteneurs Docker sont isolés de l'environnement hôte, y compris l'accès au serveur d'affichage X11[^1_1].
2. **Contexte de sécurité**: Pour qu'une application dans un conteneur puisse afficher son interface graphique, elle doit avoir accès au socket X11 de l'hôte et posséder les autorisations appropriées[^1_1][^1_2].
3. **Variables d'environnement**: La variable DISPLAY doit être correctement configurée et transmise au conteneur[^1_1][^1_7].

Le fichier docker-compose.yml fourni tente de résoudre ces problèmes avec plusieurs configurations importantes:

```yaml
environment:
  - DISPLAY=${DISPLAY}
  - QT_QPA_PLATFORM=wayland
  - XAUTHORITY=/home/wireshark_user/.Xauthority
volumes:
  - /tmp/.X11-unix:/tmp/.X11-unix
  - /run/user/1000/.mutter-Xwaylandauth.4CME32:/home/wireshark_user/.Xauthority:ro
```

Cette configuration essaie d'utiliser à la fois X11 et Wayland (via XWayland), mais ne fonctionnera pas si aucun serveur d'affichage n'est en cours d'exécution sur l'hôte[^1_1][^1_5].

## Solutions pour activer X11 avec Docker sur Debian

### Option 1: Activation du mode graphique sur l'hôte

Pour une solution complète, il faudrait activer le mode graphique sur le système Debian:

1. **Installer les paquets X11 nécessaires**:
```bash
apt-get update
apt-get install xorg lightdm
```

2. **Activer le niveau graphique par défaut**:
```bash
systemctl set-default graphical.target
```

3. **Réactiver le service x11-common**:
```bash
rm /lib/systemd/system/x11-common.service
apt-get install --reinstall x11-common
```


### Option 2: Utilisation de Xvfb (serveur X virtuel)

Si vous préférez maintenir le système en mode multi-utilisateur sans interface graphique, Xvfb offre une alternative:

1. **Installer Xvfb**:
```bash
apt-get update
apt-get install xvfb x11-xserver-utils
```

2. **Créer un script de démarrage pour Xvfb**:
```bash
Xvfb :1 -screen 0 1024x768x24 -ac &
export DISPLAY=:1
xhost +local:
```

3. **Modifier le fichier docker-compose.yml**:
```yaml
environment:
  - DISPLAY=:1
```

Cette configuration utilise un serveur X "headless" qui n'affiche rien à l'écran mais permet aux applications dans Docker d'utiliser X11[^1_7].

### Option 3: Utilisation de X11 forwarding via SSH

Une autre approche consiste à utiliser SSH pour le transfert X11:

1. **Installer les outils nécessaires**:
```bash
apt-get update
apt-get install openssh-server xauth
```

2. **Configurer SSH pour X11 forwarding**:
Dans `/etc/ssh/sshd_config`, assurez-vous que ces lignes sont présentes et non commentées:
```
X11Forwarding yes
X11DisplayOffset 10
```

3. **Se connecter via SSH avec X11 forwarding**:
```bash
ssh -X utilisateur@hôte
```

4. **Lancer Docker avec les variables d'environnement héritées**:
```bash
docker run -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix wireshark
```

Cette solution permet d'utiliser X11 sans avoir besoin d'un serveur X complet sur l'hôte Debian[^1_8].

## Configuration adaptée pour Wireshark dans Docker

### Amélioration du Dockerfile

Basé sur le Dockerfile fourni[^1_2], voici une version améliorée pour Debian (au lieu d'Arch Linux) avec une meilleure gestion X11:

```dockerfile
FROM debian:bullseye

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    wireshark \
    libcap2-bin \
    xauth \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libxkbcommon-x11-0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-render-util0 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur non-root
RUN groupadd -f wireshark && \
    useradd -m -g wireshark -s /bin/bash wireshark_user && \
    setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap && \
    chmod 750 /usr/bin/dumpcap

WORKDIR /home/wireshark_user
USER wireshark_user

# Variables d'environnement par défaut
ENV DISPLAY=:1

CMD ["wireshark"]
```


### Amélioration du docker-compose.yml

Voici une version améliorée du docker-compose.yml adapté au contexte Debian en mode multi-utilisateur:

```yaml
version: '3.8'

services:
  wireshark:
    container_name: wireshark
    build: .
    environment:
      - DISPLAY=:1
      - XAUTHORITY=/home/wireshark_user/.Xauthority
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
      - ${XAUTHORITY:-~/.Xauthority}:/home/wireshark_user/.Xauthority:ro
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - /dev/net/tun:/dev/net/tun
```

Cette configuration suppose qu'un serveur X fonctionnel est disponible sur l'affichage :1 (via Xvfb ou autre)[^1_1][^1_7].

## Conclusion

Le problème actuel est que le système Debian est configuré en mode multi-utilisateur sans serveur X actif, tout en essayant d'exécuter des applications graphiques depuis Docker. La solution dépend des besoins spécifiques:

1. Pour une utilisation régulière avec interface graphique, l'activation du mode graphique est recommandée.
2. Pour maintenir le mode serveur sans interface graphique, Xvfb offre une solution légère.
3. Pour un accès distant, le X11 forwarding via SSH est pratique et sécurisé.

Quelle que soit l'approche choisie, il est essentiel de comprendre que Docker ne peut pas afficher des applications graphiques sans un serveur X fonctionnel et accessible, qu'il soit physique ou virtuel. Les erreurs observées dans `.xsession-errors` sont symptomatiques de cette absence de serveur X11 fonctionnel.

<div style="text-align: center">⁂</div>

[^1_1]: https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/59815412/64c08224-2a5e-46f0-aaa4-ac97bd72586a/docker-compose.yml

[^1_2]: https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/59815412/b4c1edad-7b8c-49ec-8453-b7d0fc9155c4/Dockerfile.txt

[^1_3]: https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/59815412/4b20f29c-44ee-41ac-9094-5e6ec70b1f3b/README.md

[^1_4]: https://www.semanticscholar.org/paper/1165078f1a9e7045b869a3f502bc7d3e2e28e027

[^1_5]: https://www.reddit.com/r/rust/comments/155yq0a/how_to_link_with_x11_bindings/

[^1_6]: https://www.reddit.com/r/linuxquestions/comments/1ayywy4/sddm_cant_open_display_1/

[^1_7]: https://www.reddit.com/r/linuxquestions/comments/fkx110/xvfb_on_linux_docker_image_error/

[^1_8]: https://www.reddit.com/r/commandline/comments/220qsr/how_to_get_tmux_x_display_to_come_back/

[^1_9]: https://www.reddit.com/r/linux/comments/6tfy8s/purpose_of_devnull/

[^1_10]: https://www.reddit.com/r/linuxadmin/comments/x5cw50/some_confusion_about_creating_a_systemd_service/

[^1_11]: https://superuser.com/questions/1754676/how-can-i-create-a-symbolic-link-of-a-file-in-another-directory-with-relative-pa

[^1_12]: https://askubuntu.com/questions/1201103/docker-x11-fails-to-open-display

[^1_13]: https://stackoverflow.com/questions/74815279/error-with-x11-socketing-through-docker-cannot-open-display-docker-desktop-on

[^1_14]: https://stackoverflow.com/questions/44429394/x11-forwarding-of-a-gui-app-running-in-docker

[^1_15]: https://www.reddit.com/r/linuxquestions/comments/sobh92/does_devnull_always_exist/

[^1_16]: https://www.reddit.com/r/docker/comments/1f6jr0k/best_way_to_make_docker_containers_to_wait_to/

[^1_17]: https://www.reddit.com/r/linuxquestions/comments/18o66az/unable_to_unmask_nfscommon_so_i_can_mount/

[^1_18]: https://forums.docker.com/t/add-liunx-user-to-docker-service-systemd-unit-debian/68897

[^1_19]: https://askubuntu.com/questions/804946/systemctl-how-to-unmask

[^1_20]: https://stackoverflow.com/questions/76931676/cannot-execute-docker-exec-systemctl-user-for-a-docker-container-running-syste

[^1_21]: https://www.baeldung.com/linux/systemd-unmask-services

[^1_22]: https://www.reddit.com/r/linuxquestions/comments/tj7tqx/a_few_questions_about_masked_services_debian/

[^1_23]: https://memo-linux.com/cest-quoi-devnull-1/

[^1_24]: https://www.reddit.com/r/unRAID/comments/12bdyg7/a_dummys_guide_to_dockerosx_on_unraid/

[^1_25]: https://www.reddit.com/r/archlinux/comments/shda0q/authorization_required_but_no_authorization/

[^1_26]: https://www.reddit.com/r/docker/comments/ckrw4u/need_help_with_docker_swarm_service_containers_to/

[^1_27]: https://www.reddit.com/r/archlinux/comments/15s33yk/xauthority_file_in_tmp_and_not_in_user_home/

[^1_28]: https://www.reddit.com/r/OpenMediaVault/comments/z5845m/how_to_fix_failed_failed_unmounting_on_shutdown/

[^1_29]: https://www.reddit.com/r/docker/comments/17g9150/docker_failed_to_register_layer_no_space_left_on/

[^1_30]: https://www.reddit.com/r/linuxquestions/comments/f1fd7w/cannot_for_the_life_of_me_get_vnc_to_work/

[^1_31]: https://www.reddit.com/r/linuxquestions/comments/6r4ihf/docker_video402_gtkwarning_cannot_open_display/

[^1_32]: https://www.reddit.com/r/JetsonNano/comments/1iw03xu/still_cant_get_cuda_working/

[^1_33]: https://www.reddit.com/r/selfhosted/comments/sh9xa0/multiuser_browser_andor_linux_os_within_docker/

[^1_34]: https://www.reddit.com/r/linuxquestions/comments/1992xys/how_do_linux_server_users_typically_createmodify/

[^1_35]: https://www.reddit.com/r/linux/comments/ig0cyn/wsl2_gui_setup_using_xrdp_with_additional_tips/

[^1_36]: https://www.reddit.com/r/ROS/comments/x2d3ln/pangolin_x11_failed_to_open_x_display/

[^1_37]: https://www.reddit.com/r/docker/comments/11k9zl9/how_do_you_translate_a_container_to_a/

[^1_38]: https://stackoverflow.com/questions/38485607/mount-host-directory-with-a-symbolic-link-inside-in-docker-container

[^1_39]: https://stackoverflow.com/questions/57160657/x11-display-variable-is-not-set-cant-run-docker-image

[^1_40]: https://forums.docker.com/t/x11-forwarding-using-docker-desktop-for-linux/137266

[^1_41]: https://gist.github.com/CMCDragonkai/f7ca9b3ce8a64aa21ab68cf69dfc9f04

[^1_42]: https://serverfault.com/questions/1053187/systemd-fails-to-run-in-a-docker-container-when-using-cgroupv2-cgroupns-priva

[^1_43]: https://www.reddit.com/r/PleX/comments/bbgpzg/symbolic_links_not_working_with_plex/

[^1_44]: https://bbs.archlinux.org/viewtopic.php?id=272491

[^1_45]: https://superuser.com/questions/1455541/redirect-x-window-to-a-docker-container

[^1_46]: https://skandhurkat.com/post/x-forwarding-on-docker/

[^1_47]: https://docs.docker.com/engine/install/linux-postinstall/

[^1_48]: https://forums.docker.com/t/symlinks-on-shared-volumes-not-supported/9288?page=3

[^1_49]: https://linuxconfig.org/fixing-the-cannot-open-display-error-on-linux

[^1_50]: https://github.com/orgs/orbstack/discussions/1388

[^1_51]: https://briefcase.readthedocs.io/en/stable/how-to/internal/x11passthrough.html

[^1_52]: https://www.reddit.com/r/linuxquestions/comments/1bw1rra/why_is_debiansa1_being_called_to_output_to/

[^1_53]: https://www.reddit.com/r/programming/comments/fx3s07/devnull_as_a_service/

[^1_54]: https://www.reddit.com/r/linuxquestions/comments/b245pk/debian_runs_a_ton_of_strange_things_and_systemctl/

[^1_55]: https://www.reddit.com/r/linux/comments/1pj9k4/devnull_as_a_service/

[^1_56]: https://www.reddit.com/r/linux/comments/5khxeg/why_are_we_getting_rid_of_x11_while_using_systemd/

[^1_57]: https://www.reddit.com/r/linux/comments/17590l7/x11_vs_wayland_the_actual_difference/

[^1_58]: https://www.reddit.com/r/linux/comments/17jc2fr/when_do_you_expect_x11_to_become_unusable/

[^1_59]: https://bugs.debian.org/612551

[^1_60]: https://www.debian-fr.org/t/question-securite-please-remove-executable-permission-bits/74792

[^1_61]: https://unix.stackexchange.com/questions/308904/systemd-how-to-unmask-a-service-whose-unit-file-is-empty

[^1_62]: https://github.com/systemd/systemd/issues/35499

[^1_63]: https://stackoverflow.com/questions/19808927/is-it-bad-to-install-x11-common-on-debian-server


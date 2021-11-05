#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

FROM ubuntu:20.04

ENV LANG=en_GB.UTF-8
ENV TZ=Europe/London

RUN \
    # Enable partner repository (needed for codecs)
    sed -i 's/# deb http:\/\/archive.canonical.com\/ubuntu focal partner/deb http:\/\/archive.canonical.com\/ubuntu focal partner/' /etc/apt/sources.list && \
    # Remove "This system has been minimized" warning.
    rm -f /etc/update-motd.d/60-unminimize && \
    rm -f /etc/update-motd.d/98-fsck-at-reboot && \
    # Update base packages.
    apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get -fy -o Dpkg::Options::="--force-confnew" \
                -o APT::Immediate-Configure=false \
                dist-upgrade && \
    # Add the main packages
    # fonts-ubuntu was
    # automatically included in in Ubuntu 18.04 as dependencies of
    # other packages but that doesn't seem to be the case for 20.04.
    # Weirdly, without fonts-ubuntu the "Show Applications" window
    # doesn't scroll. Other users have observed different fixes.
    # https://askubuntu.com/questions/1236559/show-applications-not-scrolling-after-upgrade-to-ubuntu-20-04-from-18-04-via-19
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    base-files curl ntp add-apt-key aptdaemon \
    apt-transport-https language-pack-en gnome \
    ubuntu-minimal ubuntu-standard ubuntu-desktop \
    ubuntu-system-service ubuntu-restricted-extras \
    gconf-service gsettings-ubuntu-schemas gnome-system-log \
    gnome-shell-extension-ubuntu-dock fonts-ubuntu \
    yaru-theme-gtk yaru-theme-icon yaru-theme-sound \
    gnome-shell-extension-appindicator libpam-kwallet5 \
    gnome-control-center-faces gnome-software-plugin-snap \
    # Add packages to be similar to Ubuntu iso installation.
    thunderbird-locale-en thunderbird-locale-en-us \
    firefox-locale-en tracker-miner-fs avahi-utils vlc \
    transmission-gtk synaptic inkscape gimp pidgin remmina \
    remmina-common remmina-plugin-rdp remmina-plugin-vnc \
    remmina-plugin-nx remmina-plugin-spice \
    remmina-plugin-xdmcp mesa-utils libcanberra-pulse \
    pulseaudio-module-bluetooth paprefs pavucontrol \
    gstreamer1.0-pulseaudio pulseaudio-module-zeroconf \
    unity-asset-pool cups system-config-printer-gnome \
    # Install Display Manager and dependencies
    lightdm slick-greeter dbus-x11 && \
#    # Default libgl1-mesa-dri causes "black window" issues
#    # when software rendering. Use ppa to upgrade version.
#    add-apt-repository -y ppa:oibaf/graphics-drivers && \
#    apt-get update && DEBIAN_FRONTEND=noninteractive \
#    apt-get install -y libgl1-mesa-dri && \
    # Stop synaptic package manager being painfully slow
    rm /etc/apt/apt.conf.d/docker-gzip-indexes && \
    rm -rf /var/lib/apt/lists/* && apt-get update && \
    # Generate locales
    echo LANG=$LANG > /etc/default/locale && \
    update-locale LANG=$LANG && \
    # Set up the timezone
    echo $TZ > /etc/timezone && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    DEBIAN_FRONTEND=noninteractive \
    dpkg-reconfigure tzdata && \
    # Configure LightDM Display Manager to use
    # Xephyr instead of X
    rm /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf && \
    rm /usr/share/wayland-sessions/*.desktop && \
    # Reorganise /usr/share/xsessions to set Ubuntu as
    # default session as slick-greeter uses hardcoded names
    # to select the default session.
    rm /usr/share/xsessions/gnome.desktop && \
    mv /usr/share/xsessions/ubuntu.desktop \
       /usr/share/xsessions/ubuntu-xorg.desktop && \
    mv /usr/share/xsessions/gnome-xorg.desktop \
       /usr/share/xsessions/gnome-classic.desktop && \
    echo '#!/bin/bash\nexport XAUTHORITY=/root/.Xauthority.docker\nexport DISPLAY=:0\nexec Xephyr $1 -ac >> /var/log/lightdm/x-1.log' > /usr/bin/Xephyr-lightdm-wrapper && \
    chmod +x /usr/bin/Xephyr-lightdm-wrapper && \
    echo '[LightDM]\nminimum-display-number=1\n[Seat:*]\nuser-session=ubuntu-xorg\nxserver-command=/usr/bin/Xephyr-lightdm-wrapper' > /etc/lightdm/lightdm.conf.d/70-ubuntu.conf && \
    echo '[Greeter]\nbackground=/usr/share/backgrounds/warty-final-ubuntu.png\n' > /etc/lightdm/slick-greeter.conf && \
    # Configure console
    echo "console-setup console-setup/charmap select UTF-8" | debconf-set-selections && \
    # Fix synaptic Empty Dir::Cache::pkgcache setting not
    # handled correctly https://bugs.launchpad.net/ubuntu/+source/synaptic/+bug/1243615
    # which causes synaptic to barf with: E: Could not 
    # open file - open (2: No such file or directory)
    # E: _cache->open() failed, please report.
    sed -i 's/Dir::Cache::pkgcache ""; //' \
        /etc/apt/apt.conf.d/docker-clean && \
    # Disable getty@tty1.service to speed up desktop loading.
    rm -f /etc/systemd/system/getty.target.wants/getty@tty1.service && \
    # Fix issues with slow shutdown
    sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/' /etc/systemd/system.conf && \
    # Fix Polkit issues caused by container login being
    # considered to be an "inactive" session.
    chmod 755 /etc/polkit-1/localauthority && \
    # Date & Time
    echo "[Date & Time]\nIdentity=unix-user:*\nAction=org.gnome.controlcenter.datetime.configure\nResultAny=auth_admin_keep\nResultInactive=auth_admin_keep\nResultActive=auth_admin_keep\n" > /etc/polkit-1/localauthority/50-local.d/10-datetimemechanism.pkla && \
    # User Accounts
    echo "[Manage user accounts]\nIdentity=unix-user:*\nAction=org.gnome.controlcenter.user-accounts.administration\nResultAny=auth_admin_keep\nResultInactive=auth_admin_keep\nResultActive=auth_admin_keep\n" > /etc/polkit-1/localauthority/50-local.d/10-user-accounts.pkla && \
    # Gnome System Log
    echo "[Gnome System Log]\nIdentity=unix-user:*\nAction=org.debian.pkexec.gnome-system-log.run\nResultAny=auth_admin_keep\nResultInactive=auth_admin_keep\nResultActive=auth_admin_keep\n" > /etc/polkit-1/localauthority/50-local.d/10-system-log.pkla && \
    # System Color Manager
    echo "[System Color Manager]\nIdentity=unix-user:*\nAction=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile;org.freedesktop.color-manager.device-inhibit;org.freedesktop.color-manager.sensor-lock\nResultAny=yes\nResultInactive=yes\nResultActive=yes\n" > /etc/polkit-1/localauthority/50-local.d/10-color.pkla && \
    # Shutdown & Restart
    # Note that auth_admin_keep may be better than yes
    # here, but there seems to be an issue with the
    # authentication dialog appearing.
    echo "[Shutdown & Restart]\nIdentity=unix-user:*\nAction=org.freedesktop.login1.power-off;org.freedesktop.login1.power-off-multiple-sessions;org.freedesktop.login1.reboot;org.freedesktop.login1.reboot-multiple-sessions\nResultAny=yes\nResultInactive=yes\nResultActive=yes\n" > /etc/polkit-1/localauthority/50-local.d/10-shutdown.pkla

#-------------------------------------------------------------------------------
# Example usage
# 
# Build the image
# docker build -t ubuntu-gnome:20.04 .


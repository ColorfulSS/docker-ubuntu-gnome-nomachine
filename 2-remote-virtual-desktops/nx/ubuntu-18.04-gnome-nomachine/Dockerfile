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

FROM ubuntu-gnome-vgl:18.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    xfonts-base xfonts-75dpi xfonts-100dpi \
    xfonts-scalable net-tools xauth \
    xserver-xorg-video-dummy && \
    # Install NoMachine binary and dependencies.
    # Ensure the nx user ID is not in the normal user range.
    groupadd -r -g 2000 nx && \
    useradd -u 2000 -r -g nx nx && \
    # Try to work out the latest version from the NoMachine
    # Linux download page. If this fails set the following
    # variables manually instead.
    NOMACHINE_VERSION=$(curl -sSL \
      "https://www.nomachine.com/download/download&id=3" |\
      grep "Linux/nomachine" |\
      cut -d \' -f2 | cut -d \_ -f2-3) && \
    NOMACHINE_MAJOR_VERSION=$(echo $NOMACHINE_VERSION |\
      cut -d \. -f1-2) && \
    echo "VERSION: ${NOMACHINE_VERSION}" && \
    echo "MAJOR_VERSION: ${NOMACHINE_MAJOR_VERSION}" && \
    curl -sSL https://download.nomachine.com/download/${NOMACHINE_MAJOR_VERSION}/Linux/nomachine_${NOMACHINE_VERSION}_amd64.deb -o nomachine_${NOMACHINE_VERSION}_amd64.deb && \
    dpkg -i nomachine_${NOMACHINE_VERSION}_amd64.deb && \
    rm nomachine_${NOMACHINE_VERSION}_amd64.deb && \
    # Workaround for NoMachine configuring audio for
    # the lightdm user but not for a normal user.
    echo 'mkdir -p ~/.config/pulse\nif [ ! -f ~/.config/pulse/client.conf ]; then\ncp /etc/pulse/client.conf ~/.config/pulse/client.conf\nsed -i "s/; default-server =/default-server = unix:\/tmp\/pulse-socket/g" ~/.config/pulse/client.conf\nfi' > /etc/profile.d/create-pulse-clientconf.sh && \
    echo 'load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket' >> /etc/pulse/default.pa && \
   echo '[LightDM]\nminimum-display-number=1\n[Seat:*]\nuser-session=ubuntu-xorg\nxserver-command=Xorg -ac' > /etc/lightdm/lightdm.conf.d/70-ubuntu.conf

COPY xorg.conf /etc/X11/xorg.conf

# Debug for VirtualDesktop
# Display Number -> :0
RUN sudo sed -i 's/minimum-display-number=1/minimum-display-number=0/g' /etc/lightdm/lightdm.conf.d/70-ubuntu.conf
# Comment Optional pam_keallt*
RUN sudo sed -i 's/auth    optional        pam_kwallet.so/#auth    optional        pam_kwallet.so/g' /etc/pam.d/lightdm
RUN sudo sed -i 's/auth    optional        pam_kwallet5.so/#auth    optional        pam_kwallet5.so/g' /etc/pam.d/lightdm
# Install dbus-session
RUN sudo apt install -y dbus-user-session
# Nomachine Use EGL capture
RUN sudo /etc/NX/nxserver --egl-capture yes
RUN sudo sed -i '$a WaylandModes "egl,compositor,drm"' /usr/NX/etc/node.cfg
# Turn off Gnome Shell Animations
RUN gsettings set org.gnome.desktop.interface enable-animations false
# Install Vim
RUN sudo apt install -y vim
# Copy Install Script
COPY GeForce-XorgDisplaySettingAuto.sh /home
COPY Tesla-XorgDisplaySettingAuto.sh /home
COPY vulkan-ubuntu-18.04.sh /home
COPY vulkan-ubuntu-20.04.sh /home
WORKDIR /home

#-------------------------------------------------------------------------------
# Example usage
# 
# Build the image
# docker build -t ubuntu-gnome-nomachine:18.04 -f Dockerfile .


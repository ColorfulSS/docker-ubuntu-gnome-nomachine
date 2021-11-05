#!/bin/bash
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

################################################################################
# This script sets some additional environment configuration for docker run
# based on the version of pulseaudio being run by the host as described in
# sections 4.4.1 and 6.3.1 of the book. This script extends docker-pulseaudio.sh
# to include support for remote applications launched via ssh but behaves the
# same as docker-pulseaudio.sh for local applications.
# 
# For pulseaudio versions 7 to 9 there is a bug whereby shm files get "cleaned
# up" incorrectly in containers, so force those versions to disable shared
# memory. Pulseaudio 10 enables memfd by default, which apparently fixes this.
# See https://bugs.freedesktop.org/show_bug.cgi?id=92141
#
# This script gets the remote (to the container) host's IP from the SSH_CLIENT
# environment variable. The ssh client is the host that is local to the user
# and therefore running the desktop audio server.
#
# N.B. for this mechanism to work the script needs to be launched via ssh
# in order for the SSH_CLIENT variable to be automatically set, though if this
# variable is set in the environment by some other means it should work too e.g.
# SSH_CLIENT=<PA-daemon-IP> ./remote-noise.sh
# would also work.
#
# Another requirement is for the host running the daemon to have
# module-native-protocol-tcp installed and enabled either via paprefs or in
# /etc/pulse/default.pa (or ~/.config/pulse/default.pa)
# load-module module-native-protocol-tcp \
# auth-ip-acl=127.0.0.1;172.17.0.0/16;192.168.0.0/16 port=4713
################################################################################

# Get the ssh client IP so we know where to send the audio.
PA_HOST=$(echo ${SSH_CLIENT%% *})

if [ -z $PA_HOST ]; then
# SSH_CLIENT not set, so set flags for local application.

PULSE_VERSION=$(pulseaudio --version | sed 's/[^0-9.]*\([0-9]*\).*/\1/')
if ([[ $PULSE_VERSION -gt 6 ]] && [[ $PULSE_VERSION -lt 10 ]]); then
    PULSE_FLAGS="-e PULSE_CLIENTCONFIG=/etc/pulse/client-noshm.conf"
fi

# Populate the PULSEAUDIO_FLAGS variable as a short cut instead of
# having to set the environment and volume flags individually.
PULSEAUDIO_FLAGS="-e PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native "
PULSEAUDIO_FLAGS+="-v $XDG_RUNTIME_DIR/pulse:$XDG_RUNTIME_DIR/pulse:ro "
PULSEAUDIO_FLAGS+="-v $HOME/.config/pulse/cookie:$HOME/.config/pulse/cookie:ro "
PULSEAUDIO_FLAGS+="$PULSE_FLAGS "

else
# SSH_CLIENT set, so set flags for remote application.
TUNNEL=$(netstat -nl | grep "0.0.0.0:4714")
TUNNEL=${TUNNEL// /}
if [ -z $TUNNEL ]; then
    # No ssh tunnel set so forward directly to client IP.
    PULSEAUDIO_FLAGS="-e PULSE_SERVER=$PA_HOST:4713 "
else
    # Tunnel set so send to tunnel endpoint.
    echo "Using SSH Tunnel PULSE_SERVER=172.17.0.1:4714"
    PULSEAUDIO_FLAGS="-e PULSE_SERVER=172.17.0.1:4714 "
fi
fi

